Shader "SphereTracing/RenderShader"
{
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always
		Tags{ "Queue" = "Overlay" }

		Pass
		{
			CGPROGRAM
			
			#pragma target 5.0
			#pragma only_renderers d3d11
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			
			Texture2DArray SphereTracingArray;
			SamplerState samplerSphereTracingArray;
			
			uniform int ArrayIndex;

            // Primitive Assembler Out
			struct PAOut
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

            // Vertex Shader Out
			struct VSOut
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};
			
			struct PSOut 
			{
			    float4 color : SV_Target;
			};

			VSOut vert (PAOut IN)
			{
				VSOut OUT;
				OUT.vertex = float4(IN.vertex.xy*2,0,1);
				//OUT.vertex = UnityObjectToClipPos(IN.vertex);
				OUT.uv = IN.uv;
				return OUT;
			}
			
			PSOut frag (VSOut IN)
			{
			    PSOut OUT;
			    OUT.color = SphereTracingArray.Sample(samplerSphereTracingArray, float3(IN.uv.xy, ArrayIndex));

				return OUT;
			}
			ENDCG
		}
	}
}
