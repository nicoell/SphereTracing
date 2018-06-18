using System;
using UnityEngine;
using UnityEngine.Rendering;

namespace SphereTracing.DeferredRendering
{
	[Serializable]
	public class DeferredRenderTarget : object
	{
		[Range(0.0625f, 1f)]
		public float InternalResolutionFactor = 1.0f;

		private string _textureName;
		[NonSerialized]
		public RenderTexture RenderTexture;
		[NonSerialized]
		public RenderTexture RenderTexture2;
		[NonSerialized]
		public RenderTexture RenderTexture3;
		//public int Step { get; private set; }
		public float TargetMip { get ; private set; }

		public bool IsDownScaled { get; private set; }

		public Resolution Resolution { get; private set; }

		public void Init(string textureName, Resolution unscaledResolution, RenderTextureFormat format = RenderTextureFormat.ARGBFloat, TextureDimension dimension = TextureDimension.Tex2D, int volumeDepth = 1)
		{
			_textureName = textureName;
			if (Math.Abs(InternalResolutionFactor - 1.0f) > 0.1f) IsDownScaled = true;

			TargetMip = -Mathf.Log(InternalResolutionFactor, 2);
			//Step = Mathf.RoundToInt(1.0f / InternalResolutionFactor);
			
			Resolution = new Resolution
			{
				width = (int) Math.Floor(unscaledResolution.width * InternalResolutionFactor),
				height = (int) Math.Floor(unscaledResolution.height * InternalResolutionFactor)
			};

			RenderTexture = new RenderTexture(Resolution.width, Resolution.height, 0,
				format, RenderTextureReadWrite.Linear)
			{
				name = _textureName, 
				enableRandomWrite = true,
				useMipMap = false,
				dimension = dimension,
				volumeDepth = volumeDepth
			};
			RenderTexture.Create();
			
			RenderTexture2 = new RenderTexture(unscaledResolution.width, unscaledResolution.height, 0,
				format, RenderTextureReadWrite.Linear)
			{
				name = _textureName, 
				enableRandomWrite = true,
				useMipMap = false,
				dimension = dimension,
				volumeDepth = volumeDepth
			};
			RenderTexture2.Create();
			
			RenderTexture3 = new RenderTexture(unscaledResolution.width, unscaledResolution.height, 0,
				format, RenderTextureReadWrite.Linear)
			{
				name = _textureName, 
				enableRandomWrite = true,
				useMipMap = false,
				dimension = dimension,
				volumeDepth = volumeDepth
			};
			RenderTexture3.Create();
		}
	}
}