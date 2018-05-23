using System;

namespace SphereTracing.DeferredRendering
{
	[Serializable]
	public class InternalResolutionFactor : object
	{
		public static readonly InternalResolutionFactor Times2 = new InternalResolutionFactor("Times", 2f);
		public static readonly InternalResolutionFactor DividedBy2 = new InternalResolutionFactor("DividedBy2", 0.5f);
		public static readonly InternalResolutionFactor DividedBy4 = new InternalResolutionFactor("DividedBy4", 0.25f);
		public static readonly InternalResolutionFactor DividedBy8 = new InternalResolutionFactor("DividedBy8", 0.125f);
		public static readonly InternalResolutionFactor DividedBy16 = new InternalResolutionFactor("DividedBy16", 0.0625f);

		public float ResolutionFactor;
		public string Name;

		private InternalResolutionFactor(string name, float resolutionFactor)
		{
			Name = name;
			ResolutionFactor = resolutionFactor;
		}
	}
}