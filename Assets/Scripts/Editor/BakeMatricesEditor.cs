using UnityEditor;
using UnityEngine;
using Utils;

[CustomEditor(typeof(BakeMatrices))]
public class BakeMatricesEditor : Editor {

	public override void OnInspectorGUI()
	{
		base.OnInspectorGUI();
		serializedObject.Update();
		var controller = (BakeMatrices) target;

		if (GUILayout.Button("Print Hlsl Code"))
			controller.PrintHlslMatrices();

		serializedObject.ApplyModifiedProperties();
	}
}
