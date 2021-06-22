using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ChangeMat : MonoBehaviour
{

    [SerializeField] Material newMat;
    void Start()
    {
        ChangeMaterial(newMat);
    }
    private void Update()
    {
        if (Input.GetKey(KeyCode.W))
        {
            transform.position += new Vector3(0, 0, Time.deltaTime * 1.0f);
        }
        if (Input.GetKey(KeyCode.A))
        {
            transform.position += new Vector3(-Time.deltaTime * 1.0f, 0, 0);
        }
        if (Input.GetKey(KeyCode.S))
        {
            transform.position += new Vector3(0, 0, -Time.deltaTime * 1.0f);
        }
        if (Input.GetKey(KeyCode.D))
        {
            transform.position += new Vector3(Time.deltaTime * 1.0f, 0, 0);
        }
    }
    void ChangeMaterial(Material newMat)
    {
        Renderer[] children = GetComponentsInChildren<Renderer>();
        foreach (Renderer rend in children)
        {
            var mats = new Material[rend.materials.Length];
            for (var j = 0; j < rend.materials.Length; j++)
            {
                mats[j] = newMat;
            }
            rend.materials = mats;
        }
    }
}
