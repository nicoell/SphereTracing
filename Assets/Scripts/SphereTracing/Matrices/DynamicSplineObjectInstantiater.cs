using System.Collections.Generic;
using CurvesAndSplines;
using UnityEngine;

namespace SphereTracing.Matrices
{
	public class DynamicSplineObjectInstantiater : MonoBehaviour
	{
		public SphereTracingManager SphereTracingManager;
		public BezierSpline Spline;
		public GameObject Object;
		public int ObjectCount;
		public float SplineOffset;
		public float Duration;

		private List<GameObject> _instantiatedObjects;
		
		private void Start()
		{
			_instantiatedObjects = new List<GameObject>();
			for (int i = 0; i < ObjectCount; i++)
			{
				var newObj = Instantiate(Object, transform);
				newObj.GetComponent<SplineWalker>().spline = Spline;
				newObj.GetComponent<SplineWalker>().duration = Duration;
				newObj.GetComponent<SplineWalker>().offset = SplineOffset * i;
				newObj.GetComponent<StMatrix>().SphereTracingManager = SphereTracingManager;
				
				_instantiatedObjects.Add(newObj);
			}
		}

		private void Update()
		{
			int i = 0;
			foreach (var o in _instantiatedObjects)
			{
				o.GetComponent<SplineWalker>().duration = Duration;
				o.GetComponent<SplineWalker>().offset = SplineOffset * i;
				i++;
			}
		}
	}
}