using System;
using System.Collections.Generic;

using BirdDog.Vision;
using Xunit;

namespace BirdDog.Tests
{
    public class YuNetTests
    {
        /// <summary>The head of the astronaut, as YOLOX finds it, in pixels of the frame.</summary>
        private static readonly BoundingBox _astronautHead = new(305, 15, 443, 160);

        private static void AssertNear(float expectedX, float expectedY, float x, float y, string what)
        {
            float distance = MathF.Sqrt((x - expectedX) * (x - expectedX) + (y - expectedY) * (y - expectedY));
            Assert.True(
                distance < 4f,
                $"Expected the {what} at ({expectedX}, {expectedY}), but got ({x:F1}, {y:F1})."
            );
        }

        [Fact]
        public void Test_that_the_landmarks_of_the_astronaut_are_found_in_the_head_crop()
        {
            using var landmarker = new YuNetFaceLandmarker(TestData.LoadModel(TestData.YuNet));
            var frame = TestData.LoadFrame("astronaut_640x480.png");

            var face = landmarker.DetectOne(frame, _astronautHead);

            // NOTE (mristin):
            // We determined the landmarks with the reference Python decoding of
            // the same crop with onnxruntime, in pixels of the (not mirrored) frame.
            Assert.NotNull(face);
            Assert.True(face!.Score > 0.8f, $"Expected a confident face, got {face}.");
            AssertNear(349.3f, 97.1f, face.RightEyeX, face.RightEyeY, "right eye");
            AssertNear(391.3f, 97.6f, face.LeftEyeX, face.LeftEyeY, "left eye");
            AssertNear(368.8f, 117.1f, face.NoseX, face.NoseY, "nose");
            AssertNear(351.6f, 134.4f, face.MouthRightX, face.MouthRightY, "right corner of the mouth");
            AssertNear(386.6f, 133.1f, face.MouthLeftX, face.MouthLeftY, "left corner of the mouth");
        }

        [Fact]
        public void Test_that_a_small_head_far_away_still_has_its_landmarks()
        {
            // NOTE (mristin):
            // A player 2 m from the camera has a head of about 60 pixels; we shrink
            // the astronaut to a third, so that her head is about 50 pixels high.
            var original = TestData.LoadFrame("astronaut_640x480.png");
            const int factor = 3;
            int width = original.Width / factor;
            int height = original.Height / factor;
            var small = new byte[width * height * 3];
            for (int y = 0; y < height; y++)
            {
                for (int x = 0; x < width; x++)
                {
                    for (int c = 0; c < 3; c++)
                    {
                        int sum = 0;
                        for (int dy = 0; dy < factor; dy++)
                        {
                            for (int dx = 0; dx < factor; dx++)
                            {
                                sum += original.Rgb[((y * factor + dy) * original.Width + x * factor + dx) * 3 + c];
                            }
                        }

                        small[(y * width + x) * 3 + c] = (byte)(sum / (factor * factor));
                    }
                }
            }

            var frame = new Frame(small, width, height, 0.0);
            var head = new BoundingBox(
                _astronautHead.X1 / factor,
                _astronautHead.Y1 / factor,
                _astronautHead.X2 / factor,
                _astronautHead.Y2 / factor
            );

            using var landmarker = new YuNetFaceLandmarker(TestData.LoadModel(TestData.YuNet));
            var face = landmarker.DetectOne(frame, head);

            Assert.NotNull(face);
            Assert.True(face!.RightEyeX < face.NoseX && face.NoseX < face.LeftEyeX, $"Got {face}.");
            Assert.True(face.RightEyeY < face.NoseY && face.NoseY < face.MouthRightY, $"Got {face}.");
            AssertNear(368.8f / factor, 117.1f / factor, face.NoseX, face.NoseY, "nose");
        }

        [Fact]
        public void Test_that_no_face_is_found_in_a_blank_frame()
        {
            using var landmarker = new YuNetFaceLandmarker(TestData.LoadModel(TestData.YuNet));
            var faces = new List<FaceLandmarks>();
            landmarker.Detect(
                new Frame(new byte[640 * 480 * 3], 640, 480, 0), new[] { _astronautHead }, faces
            );

            Assert.Empty(faces);
        }

        [Fact]
        public void Test_that_the_decoding_maps_the_best_anchor_back_into_the_crop()
        {
            const int size = 64;
            const int stride = 16;
            int grid = size / stride;
            int count = grid * grid;
            var cls = new float[count];
            var obj = new float[count];
            var bbox = new float[4 * count];
            var kps = new float[10 * count];

            // The anchor at the column 2 and the row 1 sees a face.
            int index = 1 * grid + 2;
            cls[index] = 0.81f;
            obj[index] = 1f;
            bbox[4 * index + 0] = 0.5f;
            bbox[4 * index + 1] = 0.25f;
            kps[10 * index + 4] = 0.5f;
            kps[10 * index + 5] = 1f;

            // The crop is twice as large as the input, and starts at (100, 200).
            var crop = new BoundingBox(100, 200, 228, 328);
            var face = YuNet.DecodeBest(stride, cls, obj, bbox, kps, size, crop, 0.5f, null);

            Assert.NotNull(face);
            Assert.Equal(0.9f, face!.Score, 4);
            Assert.Equal(100 + (0.5f + 2) * stride * 2, face.Box.CenterX, 3);
            Assert.Equal(200 + (0.25f + 1) * stride * 2, face.Box.CenterY, 3);
            Assert.Equal(stride * 2, face.Box.Width, 3);
            Assert.Equal(100 + (0.5f + 2) * stride * 2, face.NoseX, 3);
            Assert.Equal(200 + (1f + 1) * stride * 2, face.NoseY, 3);

            // A better face from another stride wins.
            var better = new FaceLandmarks { Score = 0.95f };
            Assert.Same(better, YuNet.DecodeBest(stride, cls, obj, bbox, kps, size, crop, 0.5f, better));
        }
    }
}
