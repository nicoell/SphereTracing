using UnityEditor;
using UnityEngine;

namespace Utils
{
	[ExecuteInEditMode]
	public class HideToolGizmos : MonoBehaviour
	{
		#if UNITY_EDITOR
		private void OnEnable() { Tools.hidden = true; }

		private void OnDisable() { Tools.hidden = false; }
		#endif
	}
}