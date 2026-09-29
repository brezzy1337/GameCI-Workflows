using System.Collections;
using NUnit.Framework;
using UnityEngine;
using UnityEngine.TestTools;

namespace GameCIWorkflows.Tests.PlayMode
{
    // Day-one smoke test so CI (Unity Build Automation) has something to run.
    // Replace with real scene / MonoBehaviour tests as the project grows.
    public class SmokeTests
    {
        [UnityTest]
        public IEnumerator FrameAdvancesInPlayMode()
        {
            int startFrame = Time.frameCount;

            yield return null;

            Assert.Greater(Time.frameCount, startFrame);
        }
    }
}
