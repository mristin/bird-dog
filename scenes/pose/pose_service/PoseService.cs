using Godot;
using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;

using BirdDog.Pose;
using BirdDog.Vision;

/// <summary>
/// Recognize the bird-dog poses of the players from the results of the
/// <see cref="HandVisionService"/>, and record the detections on request.
/// </summary>
/// <remarks>
/// <para>
/// The recognition is cheap, so we run it on the main thread, once for every
/// new snapshot of the vision.
/// </para>
/// <para>
/// The game (GDScript) uses the plain API: <see cref="GetPlayers"/>. All the
/// positions are normalized
/// to [0, 1] of the camera picture as shown, i.e., mirrored if the vision mirrors.
/// </para>
/// <para>
/// The recordings hold only the detected boxes and a few small thumbnails, and
/// are written only when asked to (see <see cref="StartRecording"/>).
/// </para>
/// </remarks>
public partial class PoseService : Node
{
    [Export]
    public NodePath VisionPath = "../HandVisionService";

    [Export]
    public int PlayerCount = 1;

    /// <summary>Load the pose settings from this JSON file, if it exists.</summary>
    [Export]
    public string PoseConfigPath = "user://pose.json";

    /// <summary>Save a thumbnail of the camera this often while recording, in seconds.</summary>
    [Export]
    public double ThumbnailSeconds = 2.0;

    public PoseConfig Config { get; private set; } = new();

    private HandVisionService? _vision;
    private BirdDogPoseTracker? _tracker;
    private double _lastTimestamp = double.NaN;
    private Godot.Collections.Array<Godot.Collections.Dictionary> _players = new();

    private StreamWriter? _recording;
    private string _recordPath = "";
    private string _label = "";
    private double _lastThumbnail = double.NegativeInfinity;
    private int _thumbnails;

    private static readonly JsonSerializerOptions _jsonOptions = new() { IncludeFields = true };

    public override void _Ready()
    {
        _vision = GetNodeOrNull<HandVisionService>(VisionPath);
        if (_vision == null)
        {
            GD.PushError($"PoseService: no HandVisionService at {VisionPath}.");
        }

        if (!string.IsNullOrEmpty(PoseConfigPath) && Godot.FileAccess.FileExists(PoseConfigPath))
        {
            try
            {
                Config = PoseConfig.FromJson(Godot.FileAccess.GetFileAsString(PoseConfigPath));
                GD.Print($"Loaded the pose settings from {PoseConfigPath}.");
            }
            catch (Exception exception)
            {
                GD.PushError($"Failed to load the pose settings from {PoseConfigPath}: {exception.Message}");
            }
        }

        _tracker = new BirdDogPoseTracker(Config, PlayerCount, Mirror);
    }

    private bool Mirror => _vision?.Mirror ?? true;

    public override void _Process(double delta)
    {
        var snapshot = _vision?.Latest;
        if (snapshot == null || _tracker == null || snapshot.Timestamp == _lastTimestamp)
        {
            return;
        }

        _lastTimestamp = snapshot.Timestamp;

        var hands = new List<BoundingBox>();
        foreach (var hand in snapshot.Hands)
        {
            if (hand.IsConfirmed)
            {
                hands.Add(hand.Box);
            }
        }

        PlayerPoseState[] states = _tracker.Update(
            snapshot.Heads, hands, snapshot.FrameWidth, snapshot.FrameHeight, snapshot.Timestamp
        );

        var players = new Godot.Collections.Array<Godot.Collections.Dictionary>();
        foreach (var state in states)
        {
            var player = ToDictionary(state, snapshot.FrameWidth, snapshot.FrameHeight);
            var face = FaceOf(state.Head, snapshot.Faces);
            if (face != null)
            {
                player["face"] = FaceToDictionary(face, snapshot.FrameWidth, snapshot.FrameHeight);
            }

            players.Add(player);
        }

        _players = players;

        if (_recording != null)
        {
            Record(snapshot, states);
        }
    }

    private Rect2 ToScreen(BoundingBox box, int width, int height)
    {
        float x1 = box.X1 / width;
        float x2 = box.X2 / width;
        if (Mirror)
        {
            (x1, x2) = (1f - x2, 1f - x1);
        }

        return new Rect2(x1, box.Y1 / height, x2 - x1, box.Height / height);
    }

    private Vector2 PointToScreen(float x, float y, int width, int height)
    {
        float nx = x / width;
        return new Vector2(Mirror ? 1f - nx : nx, y / height);
    }

    /// <summary>Find the face of the head: the best one whose nose lies in it.</summary>
    private static FaceLandmarks? FaceOf(BoundingBox? head, IReadOnlyList<FaceLandmarks> faces)
    {
        if (head is not BoundingBox box)
        {
            return null;
        }

        // NOTE (mristin):
        // The head of the player is smoothed, so it lags a little behind the
        // detection in which we found the face.
        float marginX = box.Width * 0.2f;
        float marginY = box.Height * 0.2f;
        FaceLandmarks? best = null;
        foreach (var face in faces)
        {
            bool inside = face.NoseX >= box.X1 - marginX && face.NoseX <= box.X2 + marginX
                && face.NoseY >= box.Y1 - marginY && face.NoseY <= box.Y2 + marginY;
            if (inside && (best == null || face.Score > best.Score))
            {
                best = face;
            }
        }

        return best;
    }

    /// <summary>
    /// Describe the face on the screen: <c>eyes</c> and <c>mouth</c> (the
    /// corners), each as two points from the left to the right of the screen,
    /// and <c>nose</c> (the tip), normalized like the head.
    /// </summary>
    private Godot.Collections.Dictionary FaceToDictionary(FaceLandmarks face, int width, int height)
    {
        Godot.Collections.Array<Vector2> Pair(Vector2 a, Vector2 b) =>
            a.X <= b.X ? new() { a, b } : new() { b, a };

        return new Godot.Collections.Dictionary
        {
            ["eyes"] = Pair(
                PointToScreen(face.RightEyeX, face.RightEyeY, width, height),
                PointToScreen(face.LeftEyeX, face.LeftEyeY, width, height)
            ),
            ["nose"] = PointToScreen(face.NoseX, face.NoseY, width, height),
            ["mouth"] = Pair(
                PointToScreen(face.MouthRightX, face.MouthRightY, width, height),
                PointToScreen(face.MouthLeftX, face.MouthLeftY, width, height)
            ),
            ["score"] = face.Score,
        };
    }

    private static string PoseName(BirdDogPose pose) => pose.ToString().ToLowerInvariant();

    private Godot.Collections.Dictionary ToDictionary(PlayerPoseState state, int width, int height)
    {
        var hands = new Godot.Collections.Array<Godot.Collections.Dictionary>();
        foreach (var hand in state.Hands)
        {
            hands.Add(new Godot.Collections.Dictionary
            {
                ["rect"] = ToScreen(hand.Box, width, height),
                ["raised"] = hand.IsRaised,
            });
        }

        var result = new Godot.Collections.Dictionary
        {
            ["player"] = state.Player,
            ["pose"] = PoseName(state.Pose),
            ["raw_pose"] = PoseName(state.RawPose),
            ["steer"] = state.Steer,
            ["has_head"] = state.Head != null,
            ["hands"] = hands,
            ["distance"] = state.Distance switch
            {
                DistanceHint.Ok => "ok",
                DistanceHint.TooFar => "too_far",
                DistanceHint.TooClose => "too_close",
                _ => "unknown",
            },
        };

        if (state.Head is BoundingBox head)
        {
            result["head"] = ToScreen(head, width, height);
            result["head_line_y"] = state.HeadLineY / height;
        }

        return result;
    }

    /// <summary>
    /// Get the state of every player: <c>pose</c> and <c>raw_pose</c> ("absent",
    /// "rest", "left", "right" or "invalid"), <c>steer</c> (in [-1, 1], negative
    /// to the left; the higher the raised hand, the harder), <c>head</c> (Rect2, if seen),
    /// <c>head_line_y</c>, <c>hands</c> (each with <c>rect</c> and <c>raised</c>),
    /// <c>distance</c>, and <c>face</c> if the landmarks of the face were found
    /// (see <see cref="FaceToDictionary"/>).
    /// </summary>
    public Godot.Collections.Array<Godot.Collections.Dictionary> GetPlayers() => _players;

    public int GetPlayerCount() => _tracker?.PlayerCount ?? PlayerCount;

    /// <summary>Set the number of players (1 or 2); this starts the recognition afresh.</summary>
    public void SetPlayerCount(int count)
    {
        PlayerCount = Math.Clamp(count, 1, 2);
        _tracker?.SetPlayerCount(PlayerCount);
        _players = new Godot.Collections.Array<Godot.Collections.Dictionary>();
        RecordEvent("players", new Dictionary<string, object> { ["players"] = PlayerCount });
    }

    public float GetHeadLineAboveTop() => Config.HeadLineAboveTop;

    public void SetHeadLineAboveTop(float value)
    {
        Config.HeadLineAboveTop = value;
        RecordConfig();
    }

    /// <summary>Save the current pose settings to <see cref="PoseConfigPath"/>.</summary>
    public void SaveConfig()
    {
        string json = JsonSerializer.Serialize(Config, new JsonSerializerOptions { IncludeFields = true, WriteIndented = true });
        using var file = Godot.FileAccess.Open(PoseConfigPath, Godot.FileAccess.ModeFlags.Write);
        file.StoreString(json);
        GD.Print($"Saved the pose settings to {ProjectSettings.GlobalizePath(PoseConfigPath)}.");
    }

    /// <summary>Label the following recorded frames, e.g., with the step of the protocol.</summary>
    public void SetLabel(string label)
    {
        _label = label;
        RecordEvent("label", new Dictionary<string, object> { ["label"] = label });
    }

    /// <summary>
    /// Start recording the detections into a new session directory under
    /// <paramref name="directory"/> (a <c>user://</c> or absolute path).
    /// </summary>
    /// <returns>The absolute path of the session directory.</returns>
    public string StartRecording(string directory, Godot.Collections.Dictionary metadata)
    {
        StopRecording();

        string session = DateTime.Now.ToString("yyyy-MM-dd_HH-mm-ss");
        _recordPath = Path.Combine(ProjectSettings.GlobalizePath(directory), session);
        Directory.CreateDirectory(_recordPath);

        _recording = new StreamWriter(Path.Combine(_recordPath, "detections.jsonl")) { AutoFlush = true };
        _thumbnails = 0;
        _lastThumbnail = double.NegativeInfinity;

        var meta = new Dictionary<string, object>();
        foreach (var (key, value) in metadata)
        {
            meta[key.AsString()] = value.AsString();
        }

        RecordEvent("session", new Dictionary<string, object>
        {
            ["started"] = DateTime.Now.ToString("o"),
            ["players"] = GetPlayerCount(),
            ["mirror"] = Mirror,
            ["config"] = Config,
            ["metadata"] = meta,
        });

        GD.Print($"Recording the poses to {_recordPath}");
        return _recordPath;
    }

    public void StopRecording()
    {
        _recording?.Dispose();
        _recording = null;
    }

    public bool IsRecording() => _recording != null;

    public string GetRecordPath() => _recordPath;

    private void RecordConfig() => RecordEvent("config", new Dictionary<string, object> { ["config"] = Config });

    private void RecordEvent(string kind, Dictionary<string, object> fields)
    {
        if (_recording == null)
        {
            return;
        }

        fields["kind"] = kind;
        fields["t"] = _vision?.Now ?? 0.0;
        _recording.WriteLine(JsonSerializer.Serialize(fields, _jsonOptions));
    }

    private static float[] Box(BoundingBox box) => new[] { box.X1, box.Y1, box.X2, box.Y2 };

    private void Record(VisionSnapshot snapshot, PlayerPoseState[] states)
    {
        var heads = new List<float[]>();
        foreach (var head in snapshot.Heads)
        {
            heads.Add(Box(head));
        }

        // NOTE (mristin):
        // We record the tentative hands, too, so that a replay can try other
        // rules of confirmation.
        var hands = new List<Dictionary<string, object>>();
        foreach (var hand in snapshot.Hands)
        {
            hands.Add(new Dictionary<string, object>
            {
                ["id"] = hand.Id,
                ["box"] = Box(hand.Box),
                ["score"] = hand.Score,
                ["confirmed"] = hand.IsConfirmed,
            });
        }

        var poses = new List<Dictionary<string, object>>();
        foreach (var state in states)
        {
            poses.Add(new Dictionary<string, object>
            {
                ["pose"] = PoseName(state.Pose),
                ["raw"] = PoseName(state.RawPose),
                ["steer"] = state.Steer,
            });
        }

        string? thumbnail = null;
        if (snapshot.Timestamp - _lastThumbnail >= ThumbnailSeconds && _vision?.LastFrame is Frame frame)
        {
            _lastThumbnail = snapshot.Timestamp;
            thumbnail = $"thumb_{_thumbnails++:D5}.jpg";
            SaveThumbnail(frame, Path.Combine(_recordPath, thumbnail));
        }

        var fields = new Dictionary<string, object>
        {
            ["frame_t"] = snapshot.Timestamp,
            ["width"] = snapshot.FrameWidth,
            ["height"] = snapshot.FrameHeight,
            ["label"] = _label,
            ["heads"] = heads,
            ["hands"] = hands,
            ["poses"] = poses,
        };
        if (thumbnail != null)
        {
            fields["thumbnail"] = thumbnail;
        }

        RecordEvent("frame", fields);
    }

    private static void SaveThumbnail(Frame frame, string path)
    {
        // NOTE (mristin):
        // We shrink and encode on a worker thread so that the recording does not
        // slow down the game.
        System.Threading.Tasks.Task.Run(() =>
        {
            var image = Image.CreateFromData(frame.Width, frame.Height, false, Image.Format.Rgb8, frame.Rgb);
            image.Resize(160, 120, Image.Interpolation.Bilinear);
            image.SaveJpg(path, 0.8f);
        });
    }

    public override void _ExitTree()
    {
        StopRecording();
    }
}
