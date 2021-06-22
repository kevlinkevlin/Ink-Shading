// Screen post processing base class
using UnityEngine;
using System.Collections;

// Non-runtime also triggers the effect
[ExecuteInEditMode]
// Screen post-processing effects generally need to be bound to the camera
[RequireComponent(typeof(Camera))]
// Provide a post-processing base class, the main function is to directly drag the shader through the Inspector panel to generate the material corresponding to the shader
public class PostEffectBase : MonoBehaviour
{

    // Inspector panel directly dragged in
    public Shader shader = null;
    private Material _material = null;
    public Material _Material
    {
        get
        {
            if (_material == null)
                _material = GenerateMaterial(shader);
            return _material;
        }
    }

    // Create a material for the screen effects according to the shader
    protected Material GenerateMaterial(Shader shader)
    {
        if (shader == null)
            return null;
        // Need to judge whether the shader supports
        if (shader.isSupported == false)
            return null;
        Material material = new Material(shader);
        material.hideFlags = HideFlags.DontSave;
        if (material)
            return material;
        return null;
    }

}