using System;
using System.Collections.Generic;
using System.Text.Json;

using BirdDog.Vision;

// NOTE (mristin):
// The files in core/ must not depend on Godot so that we can unit-test the pose
// recognition outside of the engine. See tests/BirdDog.Tests.

namespace BirdDog.Pose
{
    /// <summary>Enumerate the poses of the bird-dog exercise which steer the boat.</summary>
    public enum BirdDogPose
    {
        /// <summary>No player is seen.</summary>
        Absent,

        /// <summary>Both hands are down (on the floor or not visible).</summary>
        Rest,

        /// <summary>Only the hand on the left of the mirrored picture is raised.</summary>
        Left,

        /// <summary>Only the hand on the right of the mirrored picture is raised.</summary>
        Right,

        /// <summary>Hands on both sides are raised.</summary>
        Invalid,
    }

    /// <summary>Tell the player whether they kneel at a good distance from the camera.</summary>
    public enum DistanceHint
    {
        Unknown,
        Ok,
        TooFar,
        TooClose,
    }

    /// <summary>Configure the recognition of the bird-dog poses.</summary>
    /// <remarks>
    /// All the lengths are in head heights, so that the recognition works at any
    /// distance from the camera.
    /// </remarks>
    public sealed class PoseConfig
    {
        /// <summary>
        /// A hand is raised if its center is above the head line, which lies this
        /// many head heights above the top edge of the head. The default, -0.95,
        /// puts the line low, at 5% above the bottom of the face (the chin), so
        /// that the kids need not lift their arms so high.
        /// </summary>
        public float HeadLineAboveTop = -0.95f;

        /// <summary>
        /// A raised hand this many head heights above the head line steers fully;
        /// below that, the steering grows with the height of the hand.
        /// </summary>
        public float FullSteerAboveLine = 1.5f;

        /// <summary>Smooth the steering with this time constant, in seconds.</summary>
        public double SteerSmoothingSeconds = 0.08;

        /// <summary>Consider only the hands at most this many head heights sideways from the head.</summary>
        public float MaxSideways = 4.0f;

        /// <summary>Consider only the hands at most this many head heights below the head.</summary>
        public float MaxBelow = 6.0f;

        /// <summary>A head lower than this fraction of the frame is too far away.</summary>
        public float MinHeadFraction = 0.06f;

        /// <summary>A head higher than this fraction of the frame is too close.</summary>
        public float MaxHeadFraction = 0.35f;

        /// <summary>A new pose counts after it has been seen this long, in seconds.</summary>
        public double ConfirmSeconds = 0.12;

        /// <summary>Keep the last head this long, in seconds, when the detector misses it.</summary>
        public double HeadLostSeconds = 0.5;

        /// <summary>Smooth the head box with this time constant, in seconds.</summary>
        public double HeadSmoothingSeconds = 0.15;

        public PoseConfig Clone() => (PoseConfig)MemberwiseClone();

        public static PoseConfig FromJson(string json)
        {
            var options = new JsonSerializerOptions
            {
                IncludeFields = true,
                ReadCommentHandling = JsonCommentHandling.Skip,
                AllowTrailingCommas = true,
            };
            return JsonSerializer.Deserialize<PoseConfig>(json, options) ?? new PoseConfig();
        }
    }

    /// <summary>Describe a hand of a player, as the pose recognition saw it.</summary>
    public readonly struct PlayerHand
    {
        public readonly BoundingBox Box;
        public readonly bool IsRaised;

        public PlayerHand(BoundingBox box, bool isRaised)
        {
            Box = box;
            IsRaised = isRaised;
        }
    }

    /// <summary>Describe the state of a player at the time of an update.</summary>
    /// <remarks>The boxes are in the original, <em>not</em> mirrored, frame.</remarks>
    public sealed class PlayerPoseState
    {
        public int Player { get; init; }

        /// <summary>The debounced pose, which steers the boat.</summary>
        public BirdDogPose Pose { get; init; }

        /// <summary>The pose of this very frame, before the debouncing.</summary>
        public BirdDogPose RawPose { get; init; }

        /// <summary>The smoothed head, or null if no player is seen.</summary>
        public BoundingBox? Head { get; init; }

        /// <summary>
        /// How hard the player steers, in [-1, 1]: negative to the left, positive
        /// to the right, 0 at rest. The higher the raised hand, the harder.
        /// </summary>
        /// <remarks>
        /// The hands push the wheel: the hand on the left of the screen lifts the
        /// left side of the wheel, which turns it clockwise, so the boat turns to
        /// the right; and the other way around.
        /// </remarks>
        public float Steer { get; init; }

        /// <summary>The y of the head line in frame pixels, or NaN without a head.</summary>
        public float HeadLineY { get; init; } = float.NaN;

        /// <summary>The hands which belong to the player.</summary>
        public IReadOnlyList<PlayerHand> Hands { get; init; } = Array.Empty<PlayerHand>();

        public DistanceHint Distance { get; init; }
    }

    /// <summary>
    /// Assign the heads and the hands to the players by the half of the picture.
    /// </summary>
    /// <remarks>
    /// Player 0 plays the left half of the screen, which shows the right half of
    /// the camera frame when the picture is mirrored.
    /// </remarks>
    public static class PlayerSplit
    {
        public static int PlayerOf(float centerX, int frameWidth, int playerCount, bool mirror)
        {
            if (playerCount <= 1)
            {
                return 0;
            }

            float x = centerX / Math.Max(1, frameWidth);
            if (mirror)
            {
                x = 1f - x;
            }

            return x < 0.5f ? 0 : 1;
        }
    }

    /// <summary>
    /// Recognize the bird-dog pose of a single player from their head and hands,
    /// debounce it and tell how hard they steer.
    /// </summary>
    public sealed class BirdDogPoseClassifier
    {
        private readonly PoseConfig _config;
        private readonly int _player;
        private readonly bool _mirror;

        private BoundingBox? _head;
        private double _headSeen = double.NegativeInfinity;
        private double _lastTime = double.NaN;

        private BirdDogPose _pose = BirdDogPose.Absent;
        private BirdDogPose _candidate = BirdDogPose.Absent;
        private double _candidateSince;

        private float _steer;
        private float _steerLeft;
        private float _steerRight;

        public BirdDogPoseClassifier(PoseConfig config, int player = 0, bool mirror = true)
        {
            _config = config;
            _player = player;
            _mirror = mirror;
        }

        public BirdDogPose Pose => _pose;

        /// <summary>
        /// Update the pose with the detections of a frame.
        /// </summary>
        /// <param name="heads">The heads of this player in this frame, in frame pixels.</param>
        /// <param name="hands">The hands in this frame (all of them; we pick the player's).</param>
        /// <param name="frameHeight">The height of the frame in pixels.</param>
        /// <param name="time">The time of the frame in seconds.</param>
        public PlayerPoseState Update(
            IReadOnlyList<BoundingBox> heads,
            IReadOnlyList<BoundingBox> hands,
            int frameHeight,
            double time
        )
        {
            UpdateHead(heads, time);

            var playerHands = new List<PlayerHand>();
            BirdDogPose raw;
            float lineY = float.NaN;
            var distance = DistanceHint.Unknown;

            if (_head is BoundingBox head)
            {
                float h = Math.Max(1f, head.Height);
                lineY = head.Y1 - _config.HeadLineAboveTop * h;

                float fraction = h / Math.Max(1, frameHeight);
                distance = fraction < _config.MinHeadFraction
                    ? DistanceHint.TooFar
                    : fraction > _config.MaxHeadFraction ? DistanceHint.TooClose : DistanceHint.Ok;

                bool raisedLeft = false;
                bool raisedRight = false;
                float steerLeft = 0f;
                float steerRight = 0f;
                foreach (var hand in hands)
                {
                    float dx = hand.CenterX - head.CenterX;
                    if (Math.Abs(dx) > _config.MaxSideways * h || hand.CenterY > head.Y2 + _config.MaxBelow * h)
                    {
                        continue;
                    }

                    bool raised = hand.CenterY < lineY;
                    playerHands.Add(new PlayerHand(hand, raised));
                    if (!raised)
                    {
                        continue;
                    }

                    float amount = Math.Clamp(
                        (lineY - hand.CenterY) / Math.Max(1e-3f, _config.FullSteerAboveLine * h), 0f, 1f
                    );

                    // NOTE (mristin):
                    // In the mirrored picture, the larger x of the frame is on the
                    // left of the screen.
                    bool onScreenLeft = _mirror ? dx > 0 : dx < 0;
                    if (onScreenLeft)
                    {
                        steerLeft = raisedLeft ? Math.Max(steerLeft, amount) : amount;
                        raisedLeft = true;
                    }
                    else
                    {
                        steerRight = raisedRight ? Math.Max(steerRight, amount) : amount;
                        raisedRight = true;
                    }
                }

                raw = (raisedLeft, raisedRight) switch
                {
                    (true, true) => BirdDogPose.Invalid,
                    (true, false) => BirdDogPose.Left,
                    (false, true) => BirdDogPose.Right,
                    _ => BirdDogPose.Rest,
                };

                // NOTE (mristin):
                // We keep the last height of a side while its hand is briefly
                // missed, so that the steering does not jump to zero mid-hold.
                if (raisedLeft)
                {
                    _steerLeft = steerLeft;
                }

                if (raisedRight)
                {
                    _steerRight = steerRight;
                }
            }
            else
            {
                raw = BirdDogPose.Absent;
            }

            Debounce(raw, time);
            UpdateSteer(time);
            _lastTime = time;

            return new PlayerPoseState
            {
                Player = _player,
                Pose = _pose,
                RawPose = raw,
                Head = _head,
                HeadLineY = lineY,
                Hands = playerHands,
                Steer = _steer,
                Distance = distance,
            };
        }

        /// <summary>
        /// Steer by the debounced pose, as hard as the raised hand is high, and
        /// smooth it so that the wheel turns without jitter.
        /// </summary>
        private void UpdateSteer(double time)
        {
            float target = _pose switch
            {
                BirdDogPose.Left => _steerLeft,
                BirdDogPose.Right => -_steerRight,
                _ => 0f,
            };

            if (double.IsNaN(_lastTime))
            {
                _steer = target;
                return;
            }

            double dt = Math.Max(0.0, time - _lastTime);
            float a = 1f - (float)Math.Exp(-dt / Math.Max(1e-3, _config.SteerSmoothingSeconds));
            _steer += (target - _steer) * a;
        }

        private void UpdateHead(IReadOnlyList<BoundingBox> heads, double time)
        {
            BoundingBox? best = null;
            foreach (var head in heads)
            {
                if (best == null || head.Area > best.Value.Area)
                {
                    best = head;
                }
            }

            if (best is BoundingBox target)
            {
                if (_head is BoundingBox previous && !double.IsNaN(_lastTime))
                {
                    double dt = Math.Max(0.0, time - _lastTime);
                    float a = 1f - (float)Math.Exp(-dt / Math.Max(1e-3, _config.HeadSmoothingSeconds));
                    _head = new BoundingBox(
                        previous.X1 + (target.X1 - previous.X1) * a,
                        previous.Y1 + (target.Y1 - previous.Y1) * a,
                        previous.X2 + (target.X2 - previous.X2) * a,
                        previous.Y2 + (target.Y2 - previous.Y2) * a
                    );
                }
                else
                {
                    _head = target;
                }

                _headSeen = time;
            }
            else if (time - _headSeen > _config.HeadLostSeconds)
            {
                _head = null;
            }
        }

        private void Debounce(BirdDogPose raw, double time)
        {
            if (raw == _pose)
            {
                _candidate = raw;
                return;
            }

            if (raw != _candidate)
            {
                _candidate = raw;
                _candidateSince = time;
            }

            if (time - _candidateSince >= _config.ConfirmSeconds - 1e-9)
            {
                _pose = raw;
            }
        }
    }

    /// <summary>Recognize the poses of one or two players in the same camera picture.</summary>
    public sealed class BirdDogPoseTracker
    {
        private readonly PoseConfig _config;
        private readonly bool _mirror;
        private BirdDogPoseClassifier[] _classifiers = Array.Empty<BirdDogPoseClassifier>();
        private readonly List<BoundingBox>[] _heads = { new(), new() };

        public BirdDogPoseTracker(PoseConfig config, int playerCount = 1, bool mirror = true)
        {
            _config = config;
            _mirror = mirror;
            SetPlayerCount(playerCount);
        }

        public PoseConfig Config => _config;

        public int PlayerCount => _classifiers.Length;

        /// <summary>Set the number of players (1 or 2) and start their recognition afresh.</summary>
        public void SetPlayerCount(int playerCount)
        {
            playerCount = Math.Clamp(playerCount, 1, 2);
            _classifiers = new BirdDogPoseClassifier[playerCount];
            for (int i = 0; i < playerCount; i++)
            {
                _classifiers[i] = new BirdDogPoseClassifier(_config, i, _mirror);
            }
        }

        /// <summary>Update all the players with the detections of a frame.</summary>
        public PlayerPoseState[] Update(
            IReadOnlyList<BoundingBox> heads,
            IReadOnlyList<BoundingBox> hands,
            int frameWidth,
            int frameHeight,
            double time
        )
        {
            foreach (var list in _heads)
            {
                list.Clear();
            }

            foreach (var head in heads)
            {
                _heads[PlayerSplit.PlayerOf(head.CenterX, frameWidth, PlayerCount, _mirror)].Add(head);
            }

            var states = new PlayerPoseState[PlayerCount];
            for (int i = 0; i < PlayerCount; i++)
            {
                // NOTE (mristin):
                // We give each player only the hands of their half, so that the
                // raised hand of the neighbour never steers the wrong boat.
                var playerHands = new List<BoundingBox>();
                foreach (var hand in hands)
                {
                    if (PlayerSplit.PlayerOf(hand.CenterX, frameWidth, PlayerCount, _mirror) == i)
                    {
                        playerHands.Add(hand);
                    }
                }

                states[i] = _classifiers[i].Update(_heads[i], playerHands, frameHeight, time);
            }

            return states;
        }
    }
}  // namespace BirdDog.Pose
