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

		private string _name;
		[NonSerialized]
		private RenderTexture _renderTexture;
		private bool _isDownScaled;
		[NonSerialized]
		private RenderTexture _renderTextureDownScaled;
		private Resolution _scaledResolution;
		private int _step;

		public void Init(string name, Resolution unscaledResolution, RenderTextureFormat format = RenderTextureFormat.ARGBFloat, TextureDimension dimension = TextureDimension.Tex2D, int volumeDepth = 1)
		{
			_name = name;
			if (Math.Abs(InternalResolutionFactor - 1.0f) > 0.1f) _isDownScaled = true;

			_renderTexture = new RenderTexture(unscaledResolution.width, unscaledResolution.height, 0,
				format, RenderTextureReadWrite.Linear)
			{
				enableRandomWrite = true,
				useMipMap = false,
				dimension = dimension,
				volumeDepth = volumeDepth
				
			};
			_renderTexture.Create();

			if (_isDownScaled)
			{
				_step = Mathf.RoundToInt(1.0f / InternalResolutionFactor);
				_scaledResolution = new Resolution
				{
					width = (int) Math.Floor(unscaledResolution.width * InternalResolutionFactor),
					height = (int) Math.Floor(unscaledResolution.height * InternalResolutionFactor)
				};
				_renderTextureDownScaled = new RenderTexture(_scaledResolution.width, _scaledResolution.height, 0,
					format, RenderTextureReadWrite.Linear)
				{
					enableRandomWrite = true,
					useMipMap = false,
					dimension = dimension,
					volumeDepth = volumeDepth
				};
				_renderTextureDownScaled.Create();
			}
			else
			{
				_step = 1;
			}
		}
		
		public void BindToComputeShader(ComputeShader computeShader, params int[] kernels)
		{
			computeShader.SetInt(_name + "Step", _step);
			foreach (var kernel in kernels)
			{
				computeShader.SetTexture(kernel, _name + "Target", _isDownScaled ? _renderTextureDownScaled : _renderTexture);
				computeShader.SetTexture(kernel, _name + "Deferred", _renderTexture);
			}
		}
	}
}