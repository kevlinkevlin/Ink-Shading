using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;
public class PostProcessingEffects : MonoBehaviour
{
    // Start is called before the first frame update
    public PostProcessVolume volume;
    private Bloom _Bloom;
    private Vignette _Vignette;
    private bool loop = true;
    void Start()
    {
        volume = GetComponent<PostProcessVolume>();
        _Bloom = volume.profile.GetSetting<Bloom>();
        _Vignette = volume.profile.GetSetting<Vignette>();
        _Bloom.intensity.value = 0;
        _Vignette.intensity.value = 0;
    }

    // Update is called once per frame
    void Update()
    {
        // print(_Vignette.intensity.value);
        _Bloom.intensity.value = Mathf.Lerp(_Bloom.intensity.value, 15, .05f * Time.deltaTime);
        if (loop)
        {
            if (_Vignette.intensity.value >= 0.9)
            {
                loop = false;
            }
            // _Vignette.intensity.value = Mathf.Lerp(_Vignette.intensity.value, 1, .5f * Time.deltaTime);
        }
        else
        {
            if (_Vignette.intensity.value < 0.1)
            {
                loop = true;
            }
            // _Vignette.intensity.value = Mathf.Lerp(_Vignette.intensity.value, 0, .5f * Time.deltaTime);
        }
    }


}
