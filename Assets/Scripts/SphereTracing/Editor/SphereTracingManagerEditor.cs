using UnityEditor;
using UnityEngine;

namespace SphereTracing.Editor
{
	[CustomEditor(typeof(SphereTracingManager))]
	public class SphereTracingManagerEditor : UnityEditor.Editor
	{
		private UnityEditor.Editor _editor;

		public override void OnInspectorGUI()
		{
			base.OnInspectorGUI();
			serializedObject.Update();
			var controller = (SphereTracingManager) target;

			if (GUILayout.Button("Reload"))
				controller.Awake();

			serializedObject.ApplyModifiedProperties();
		}
	}
}