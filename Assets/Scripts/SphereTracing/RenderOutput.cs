using System.Diagnostics.CodeAnalysis;

namespace SphereTracing {
	[SuppressMessage("ReSharper", "UnusedMember.Global")]
	public enum RenderOutput
	{
		Color = 0,
		SurfaceColor, 
		RepresentColor,
		SurfacePosition,
		SurfaceMaterialId,
		SurfaceRayDirection,
		SurfaceDepth,
		SurfaceNormal,
		SurfaceAlpha,
		SurfaceBentNormal,
		SurfaceDiffuseOcclusion,
		SurfaceSpecularOcclusion,
		RepresentPosition,
		RepresentMaterialId,
		RepresentRayDirection,
		RepresentDepth,
		RepresentNormal,
		RepresentAlpha,
		RepresentBentNormal,
		RepresentDiffuseOcclusion,
		RepresentSpecularOcclusion,
		SurfaceLowResDepth
		
	}
}