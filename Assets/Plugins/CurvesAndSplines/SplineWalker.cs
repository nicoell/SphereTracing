using UnityEngine;

namespace CurvesAndSplines
{
	public class SplineWalker : MonoBehaviour
	{

		public BezierSpline spline;

		public float duration;
		[Range(0, 1)]
		public float offset;

		public bool lookForward;

		public SplineWalkerMode mode;
		
		private float progress;
		private bool goingForward = true;

		private void Update()
		{
			if (goingForward)
			{
				progress += Time.deltaTime / duration;
				if (progress > 1f)
				{
					if (mode == SplineWalkerMode.Once)
					{
						progress = 1f;
					} else if (mode == SplineWalkerMode.Loop)
					{
						progress -= 1f;
					} else
					{
						progress = 2f - progress;
						goingForward = false;
					}
				}
			} else
			{
				progress -= Time.deltaTime / duration;
				if (progress < 0f)
				{
					progress = -progress;
					goingForward = true;
				}
			}

			Vector3 position = spline.GetPoint((progress + offset) % 1);
			transform.localPosition = position;
			if (lookForward)
			{
				transform.LookAt(position + spline.GetDirection((progress + offset) % 1));
			}
		}
	}
}