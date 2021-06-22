//hang on the camera
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class ChineseInkPostEffect : PostEffectBase
{
    /// <summary>
    /// Drop resolution is not operating
    /// </summary>
    [Range(0, 5), Tooltip("[降取樣次數]向下取樣的次數。此值越大,則取樣間隔越大,需要處理的畫素點越少,執行速度越快。")]
    public int downSample = 1;
    /// <summary>
    /// Gaussian fuzzy sampling scaling factor
    /// </summary>
    [Range(0, 5)]
    public int samplerScale = 1;
    /// <summary>
    /// Gaussian fuzzy iterations
    /// </summary>
    [Range(0, 10), Tooltip("[迭代次數]此值越大,則模糊操作的迭代次數越多，模糊效果越好，但消耗越大。")]
    public int count = 1;
    /// <summary>
    /// edge width
    /// </summary>
    [Range(0.0f, 10.0f)]
    public float edgeWidth = 3.0f;
    /// <summary>
    /// minimum width of the edge
    /// </summary>
    [Range(0.0f, 1.0f)]
    public float sensitive = 0.35f;
    /// <summary>
    /// Brush filter coefficient
    /// </summary>
    [Range(0, 20)]
    public int paintFactor = 4;
    /// <summary>
    /// Noise map
    /// </summary>
    public Texture noiseTexture;
    private Camera cam;
    private void Start()
    {
        cam = GetComponent<Camera>();
        // Open the depth normal map
        cam.depthTextureMode = DepthTextureMode.DepthNormals;
    }
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (_Material)
        {
            RenderTexture temp1 = RenderTexture.GetTemporary(source.width >> downSample, source.height >> downSample, 0, source.format);
            RenderTexture temp2 = RenderTexture.GetTemporary(source.width >> downSample, source.height >> downSample, 0, source.format);

            Graphics.Blit(source, temp1);
            for (int i = 0; i < count; i++)
            {
                //Gaussian blur horizontally twice (pass0)
                _Material.SetVector("_offsets", new Vector4(0, samplerScale, 0, 0));
                Graphics.Blit(temp1, temp2, _Material, 0);
                _Material.SetVector("_offsets", new Vector4(samplerScale, 0, 0, 0));
                Graphics.Blit(temp2, temp1, _Material, 0);
            }

            // stroke (pass1)
            _Material.SetTexture("_BlurTex", temp1);
            _Material.SetTexture("_NoiseTex", noiseTexture);
            _Material.SetFloat("_EdgeWidth", edgeWidth);
            _Material.SetFloat("_Sensitive", sensitive);
            Graphics.Blit(temp1, temp2, _Material, 1);

            //brush filter (pass2)
            _Material.SetTexture("_PaintTex", temp2);
            _Material.SetInt("_PaintFactor", paintFactor);
            Graphics.Blit(temp2, destination, _Material, 2);

            RenderTexture.ReleaseTemporary(temp1);
            RenderTexture.ReleaseTemporary(temp2);
        }
    }
}
