using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SurfaceTrackController : MonoBehaviour
{

    // Use this for initialization
    public Camera _camera;
    public Shader _drawshader, _initshader;

    [Range(0.1f, 2.0f)]
    public float _TrackSize;
    [Range(0.0f, 0.05f)]
    public float _TrackStrength;
    private CustomRenderTexture _splatmap;
    private Material _sandMaterial, _drawMaterial, _initMaterial;
    private RaycastHit _hit;
    private Vector4 lastHitCord;


    void Start()
    {
        if (_camera == null)
            _camera = Camera.main;
        _drawMaterial = new Material(_drawshader);
        _drawMaterial.SetVector("_Color", Color.red);
        _drawMaterial.SetFloat("_TrackSize", _TrackSize);
        _drawMaterial.SetFloat("_TrackStrength", _TrackStrength);
        _drawMaterial.SetVectorArray("_Coordinates", new Vector4[4]);
        _sandMaterial = GetComponent<MeshRenderer>().material;
        _splatmap = new CustomRenderTexture(4096, 4096, RenderTextureFormat.ARGBFloat);
        _initMaterial = new Material(_initshader);
        RenderTexture temp = RenderTexture.GetTemporary(_splatmap.width, _splatmap.height, 0, RenderTextureFormat.ARGBFloat);
        Graphics.Blit(_splatmap, temp);
        Graphics.Blit(temp, _splatmap, _initMaterial); //将上一帧绘制出来的splat作为这一帧的输入tex
        _sandMaterial.SetTexture("_Splat", _splatmap);
        RenderTexture.ReleaseTemporary(temp);
        lastHitCord = Vector4.one;//one 表示null
    }

    // Update is called once per frame
    void Update()
    {
        if (Input.GetKey(KeyCode.Mouse0))
        {
            if (Physics.Raycast(_camera.ScreenPointToRay(Input.mousePosition), out _hit))
            {

                Vector4 newHitCod = new Vector4(_hit.textureCoord.x, _hit.textureCoord.y, 0, 0);
                if (newHitCod != lastHitCord)
                {

                    Vector4[] test = new Vector4[2];
                    test[0] = newHitCod;
                    test[1] = lastHitCord;
                    DrawStep(test);
                    lastHitCord = newHitCod;
                }



            }
        }
        else
        {
            lastHitCord = Vector4.one;//one 表示null
        }
    }
    public void DrawStep(Vector4[] coordsList)
    {
        int arrayLength = coordsList.Length;
        if (arrayLength == 0)
            return;
 
        _drawMaterial.SetVectorArray("_Coordinates", coordsList);
        _drawMaterial.SetFloat("_CoordsNum", coordsList.Length);
        //Debug.Log(coordsList.Length);
        RenderTexture temp = RenderTexture.GetTemporary(_splatmap.width, _splatmap.height, 0, RenderTextureFormat.ARGBFloat);
        Graphics.Blit(_splatmap, temp);//
                                       //Graphics.DrawTexture()
        Graphics.Blit(temp, _splatmap, _drawMaterial); //将上一帧绘制出来的splat作为这一帧的输入tex
        RenderTexture.ReleaseTemporary(temp);
    }

    private void OnGUI()
    {
        GUI.DrawTexture(new Rect(0, 0, 256, 256), _splatmap, ScaleMode.ScaleToFit, false, 1);
    }
}
