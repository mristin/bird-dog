using System.Collections.Generic;

using BirdDog.Pose;
using BirdDog.Vision;

using Xunit;

namespace BirdDog.Tests
{
    public class BirdDogPoseTests
    {
        private const int Width = 640;
        private const int Height = 480;

        // NOTE (mristin):
        // A head of 60 px in the middle of the frame; its top edge is at y = 200.
        private static readonly BoundingBox Head = BoundingBox.FromCenter(320, 230, 50, 60);

        // In the raw (not mirrored) frame, the larger x is on the left of the
        // mirrored screen.
        private static readonly BoundingBox ScreenLeftRaised = BoundingBox.FromCenter(400, 170, 40, 40);
        private static readonly BoundingBox ScreenRightRaised = BoundingBox.FromCenter(240, 170, 40, 40);
        private static readonly BoundingBox ScreenLeftDown = BoundingBox.FromCenter(400, 380, 40, 40);
        private static readonly BoundingBox ScreenRightDown = BoundingBox.FromCenter(240, 380, 40, 40);

        private static PoseConfig Config() => new()
        {
            ConfirmSeconds = 0.3,
            HeadLostSeconds = 0.5,
        };

        /// <summary>Feed the same detections at 20 Hz for the given duration.</summary>
        private static PlayerPoseState Feed(
            BirdDogPoseClassifier classifier,
            ref double time,
            double seconds,
            BoundingBox[] heads,
            BoundingBox[] hands
        )
        {
            PlayerPoseState state = classifier.Update(heads, hands, Height, time);
            int steps = (int)System.Math.Round(seconds / 0.05);
            for (int i = 0; i < steps; i++)
            {
                time += 0.05;
                state = classifier.Update(heads, hands, Height, time);
            }

            return state;
        }

        [Fact]
        public void Test_no_head_is_absent()
        {
            var classifier = new BirdDogPoseClassifier(Config());
            double time = 0;
            var state = Feed(classifier, ref time, 1.0, new BoundingBox[0], new[] { ScreenLeftRaised });
            Assert.Equal(BirdDogPose.Absent, state.Pose);
            Assert.Null(state.Head);
        }

        [Fact]
        public void Test_both_hands_down_is_rest()
        {
            var classifier = new BirdDogPoseClassifier(Config());
            double time = 0;
            var state = Feed(classifier, ref time, 1.0, new[] { Head }, new[] { ScreenLeftDown, ScreenRightDown });
            Assert.Equal(BirdDogPose.Rest, state.Pose);
            Assert.Equal(2, state.Hands.Count);
            Assert.All(state.Hands, hand => Assert.False(hand.IsRaised));
        }

        [Fact]
        public void Test_no_hands_is_rest()
        {
            var classifier = new BirdDogPoseClassifier(Config());
            double time = 0;
            var state = Feed(classifier, ref time, 1.0, new[] { Head }, new BoundingBox[0]);
            Assert.Equal(BirdDogPose.Rest, state.Pose);
        }

        [Fact]
        public void Test_raised_hand_on_screen_left_is_left_when_mirrored()
        {
            var classifier = new BirdDogPoseClassifier(Config(), mirror: true);
            double time = 0;
            var state = Feed(classifier, ref time, 1.0, new[] { Head }, new[] { ScreenLeftRaised, ScreenRightDown });
            Assert.Equal(BirdDogPose.Left, state.Pose);
        }

        [Fact]
        public void Test_raised_hand_with_the_other_invisible_is_right()
        {
            var classifier = new BirdDogPoseClassifier(Config(), mirror: true);
            double time = 0;
            var state = Feed(classifier, ref time, 1.0, new[] { Head }, new[] { ScreenRightRaised });
            Assert.Equal(BirdDogPose.Right, state.Pose);
        }

        [Fact]
        public void Test_sides_swap_without_mirror()
        {
            var classifier = new BirdDogPoseClassifier(Config(), mirror: false);
            double time = 0;
            var state = Feed(classifier, ref time, 1.0, new[] { Head }, new[] { ScreenLeftRaised });
            Assert.Equal(BirdDogPose.Right, state.Pose);
        }

        [Fact]
        public void Test_both_raised_is_invalid()
        {
            var classifier = new BirdDogPoseClassifier(Config());
            double time = 0;
            var state = Feed(classifier, ref time, 1.0, new[] { Head }, new[] { ScreenLeftRaised, ScreenRightRaised });
            Assert.Equal(BirdDogPose.Invalid, state.Pose);
        }

        [Fact]
        public void Test_a_short_flicker_does_not_change_the_pose()
        {
            var classifier = new BirdDogPoseClassifier(Config());
            double time = 0;
            Feed(classifier, ref time, 1.0, new[] { Head }, new[] { ScreenLeftDown });

            time += 0.05;
            var state = Feed(classifier, ref time, 0.15, new[] { Head }, new[] { ScreenLeftRaised });
            Assert.Equal(BirdDogPose.Rest, state.Pose);
            Assert.Equal(BirdDogPose.Left, state.RawPose);

            time += 0.05;
            state = Feed(classifier, ref time, 0.5, new[] { Head }, new[] { ScreenLeftDown });
            Assert.Equal(BirdDogPose.Rest, state.Pose);
        }

        [Fact]
        public void Test_the_head_survives_a_brief_miss()
        {
            var classifier = new BirdDogPoseClassifier(Config());
            double time = 0;
            Feed(classifier, ref time, 1.0, new[] { Head }, new[] { ScreenLeftRaised });

            time += 0.05;
            var state = Feed(classifier, ref time, 0.3, new BoundingBox[0], new[] { ScreenLeftRaised });
            Assert.Equal(BirdDogPose.Left, state.Pose);

            time += 0.05;
            state = Feed(classifier, ref time, 1.0, new BoundingBox[0], new[] { ScreenLeftRaised });
            Assert.Equal(BirdDogPose.Absent, state.Pose);
        }

        [Fact]
        public void Test_far_away_hands_are_ignored()
        {
            var classifier = new BirdDogPoseClassifier(Config());
            double time = 0;
            var farAway = BoundingBox.FromCenter(20, 150, 40, 40);
            var state = Feed(classifier, ref time, 1.0, new[] { Head }, new[] { farAway });
            Assert.Equal(BirdDogPose.Rest, state.Pose);
            Assert.Empty(state.Hands);
        }

        [Fact]
        public void Test_the_head_line_moves_with_the_config()
        {
            var config = Config();
            config.HeadLineAboveTop = 0.5f;
            var classifier = new BirdDogPoseClassifier(config);
            double time = 0;

            // NOTE (mristin):
            // The hand at y = 170 is above the top edge (200), but below the line
            // at 200 - 0.5 * 60 = 170.
            var state = Feed(classifier, ref time, 1.0, new[] { Head }, new[] { ScreenLeftRaised });
            Assert.Equal(170f, state.HeadLineY, 3);
            Assert.Equal(BirdDogPose.Rest, state.Pose);
        }

        [Fact]
        public void Test_the_default_head_line_lies_just_above_the_bottom_of_the_face()
        {
            var classifier = new BirdDogPoseClassifier(Config());
            double time = 0;
            var state = Feed(classifier, ref time, 1.0, new[] { Head }, new BoundingBox[0]);
            Assert.Equal(Head.Y1 + 0.95f * Head.Height, state.HeadLineY, 3);

            // NOTE (mristin):
            // A hand at the mouth (just above the chin) counts as raised.
            var atTheMouth = BoundingBox.FromCenter(400, 250, 40, 40);
            state = Feed(classifier, ref time, 1.0, new[] { Head }, new[] { atTheMouth });
            Assert.Equal(BirdDogPose.Left, state.Pose);
        }

        [Fact]
        public void Test_steer_grows_with_the_height_of_the_hand()
        {
            // NOTE (mristin):
            // The line is at y = 200 + 0.95 * 60 = 257, and the full steering at
            // 257 - 1.5 * 60 = 167.
            var low = BoundingBox.FromCenter(400, 242, 40, 40);
            var middle = BoundingBox.FromCenter(400, 212, 40, 40);
            var high = BoundingBox.FromCenter(400, 100, 40, 40);

            var steers = new List<float>();
            foreach (var hand in new[] { low, middle, high })
            {
                var classifier = new BirdDogPoseClassifier(Config());
                double time = 0;
                steers.Add(Feed(classifier, ref time, 2.0, new[] { Head }, new[] { hand }).Steer);
            }

            // NOTE (mristin):
            // The left hand lifts the left side of the wheel, which turns the boat right.
            Assert.InRange(steers[0], 0.1f, 0.2f);
            Assert.InRange(steers[1], 0.45f, 0.55f);
            Assert.InRange(steers[2], 0.99f, 1.0f);
        }

        [Fact]
        public void Test_the_right_hand_steers_left_and_rest_steers_straight()
        {
            var classifier = new BirdDogPoseClassifier(Config());
            double time = 0;
            var state = Feed(classifier, ref time, 2.0, new[] { Head }, new[] { ScreenRightRaised });
            Assert.True(state.Steer < -0.5f);

            time += 0.05;
            state = Feed(classifier, ref time, 2.0, new[] { Head }, new[] { ScreenRightDown });
            Assert.Equal(BirdDogPose.Rest, state.Pose);
            Assert.InRange(state.Steer, -0.01f, 0.01f);
        }

        [Fact]
        public void Test_steer_waits_for_the_debounced_pose()
        {
            var classifier = new BirdDogPoseClassifier(Config());
            double time = 0;
            Feed(classifier, ref time, 1.0, new[] { Head }, new[] { ScreenLeftDown });

            time += 0.05;
            var state = Feed(classifier, ref time, 0.15, new[] { Head }, new[] { ScreenLeftRaised });
            Assert.Equal(0f, state.Steer);
        }

        [Fact]
        public void Test_distance_hints()
        {
            double time = 0;
            var far = new BirdDogPoseClassifier(Config());
            var tiny = BoundingBox.FromCenter(320, 230, 15, 20);
            Assert.Equal(DistanceHint.TooFar, Feed(far, ref time, 0.1, new[] { tiny }, new BoundingBox[0]).Distance);

            var close = new BirdDogPoseClassifier(Config());
            var huge = BoundingBox.FromCenter(320, 240, 200, 240);
            Assert.Equal(DistanceHint.TooClose, Feed(close, ref time, 0.1, new[] { huge }, new BoundingBox[0]).Distance);

            var ok = new BirdDogPoseClassifier(Config());
            Assert.Equal(DistanceHint.Ok, Feed(ok, ref time, 0.1, new[] { Head }, new BoundingBox[0]).Distance);
        }

        [Fact]
        public void Test_two_players_get_their_own_halves()
        {
            var tracker = new BirdDogPoseTracker(Config(), playerCount: 2, mirror: true);

            // NOTE (mristin):
            // Mirrored, the right half of the frame is player 0 (the left of the screen).
            var head0 = BoundingBox.FromCenter(480, 230, 50, 60);
            var head1 = BoundingBox.FromCenter(160, 230, 50, 60);
            var raised0 = BoundingBox.FromCenter(540, 170, 40, 40);  // screen-left of head 0
            var raised1 = BoundingBox.FromCenter(100, 170, 40, 40);  // screen-right of head 1

            PlayerPoseState[] states = tracker.Update(new[] { head0, head1 }, new[] { raised0, raised1 }, Width, Height, 0);
            for (double time = 0.05; time <= 1.0; time += 0.05)
            {
                states = tracker.Update(new[] { head0, head1 }, new[] { raised0, raised1 }, Width, Height, time);
            }

            Assert.Equal(BirdDogPose.Left, states[0].Pose);
            Assert.Equal(BirdDogPose.Right, states[1].Pose);
        }

        [Theory]
        [InlineData(100f, 1, true, 0)]
        [InlineData(100f, 2, true, 1)]
        [InlineData(500f, 2, true, 0)]
        [InlineData(100f, 2, false, 0)]
        public void Test_player_split(float x, int players, bool mirror, int expected)
        {
            Assert.Equal(expected, PlayerSplit.PlayerOf(x, Width, players, mirror));
        }
    }
}
