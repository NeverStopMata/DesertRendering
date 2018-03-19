using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DrawWithMouse : MonoBehaviour {
    public Camera _camera;
    public Shader _drawshader,_initshader;

    private CustomRenderTexture _splatmap;
    private Material _snowMaterial, _drawMaterial,_initMaterial;
    private RaycastHit _hit;
    private Vector4 lastHitCord;
    // Use this for initialization
    void Start () {
        _drawMaterial = new Material (_drawshader);
        _drawMaterial.SetVector ("_Color", Color.red);
        _drawMaterial.SetVector("_TrackInf", new Vector4(1000,0,0,0));
        _snowMaterial = GetComponent<MeshRenderer> ().material;
        _splatmap = new CustomRenderTexture (1024, 1024, RenderTextureFormat.ARGBFloat);

        //初始化splatmap 为一张（0.5，0，0，1.0）颜色的贴图；
        _initMaterial = new Material(_initshader);
        RenderTexture temp = RenderTexture.GetTemporary(_splatmap.width, _splatmap.height, 0, RenderTextureFormat.ARGBFloat);
        Graphics.Blit(_splatmap, temp);
        Graphics.Blit(temp, _splatmap, _initMaterial); //将上一帧绘制出来的splat作为这一帧的输入tex

        _snowMaterial.SetTexture ("_Splat", _splatmap);
        RenderTexture.ReleaseTemporary(temp);
        lastHitCord = Vector4.one;//one 表示null
        //lastTime = 0;

    }

    // Update is called once per frame
    void Update () {
        if (Input.GetKey (KeyCode.Mouse0)) {
            if (Physics.Raycast (_camera.ScreenPointToRay (Input.mousePosition), out _hit)) {
                Vector4 newHitCod = new Vector4(_hit.textureCoord.x, _hit.textureCoord.y, 0, 0);
                if(newHitCod != lastHitCord)
                {
                    _drawMaterial.SetVector("_Coordinate", newHitCod);
                    //if (lastHitCord == Vector4.one)
                    //    lastHitCord = newHitCod;
                    _drawMaterial.SetVector("_LastCoordinate", lastHitCord);
                    lastHitCord = newHitCod;
                    RenderTexture temp = RenderTexture.GetTemporary(_splatmap.width, _splatmap.height, 0, RenderTextureFormat.ARGBFloat);
                    Graphics.Blit(_splatmap, temp);
                    Graphics.Blit(temp, _splatmap, _drawMaterial); //将上一帧绘制出来的splat作为这一帧的输入tex
                    RenderTexture.ReleaseTemporary(temp);
                }
               


            }
        }
        else
        {
            lastHitCord = Vector4.one;//one 表示null
        }
    }
    private void OnGUI () {
        GUI.DrawTexture (new Rect (0, 0, 256, 256), _splatmap, ScaleMode.ScaleToFit, false, 1);
    }
}