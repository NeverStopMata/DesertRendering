using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SurfaceTrackController : MonoBehaviour {

    // Use this for initialization
    public Camera _camera;
    public Shader _drawshader, _initshader;
    public RenderTexture _splatmap; //,temp;
    [Range (0.1f, 2.0f)]
    public float _TrackSize;
    [Range (0.0f, 0.05f)]
    public float _TrackStrength;

    [Range (1.0f, 10.0f)]
    public float _SampleAreaSize;

    [Range (-0.5f, 0.5f)]
    public float _HeightOffset;
    private Material _sandMaterial, _drawMaterial, _initMaterial;
    private RaycastHit _hit;
    private Vector4 lastHitCord;
    private Rect debugShowing;

    void Start () {
        if (_camera == null)
            _camera = Camera.main;
        _drawMaterial = new Material (_drawshader);
        _drawMaterial.SetVector ("_Color", Color.red);
        _drawMaterial.SetFloat ("_TrackSize", _TrackSize);
        _drawMaterial.SetFloat ("_TrackStrength", _TrackStrength);
        _drawMaterial.SetVectorArray ("_Coordinates", new Vector4[4]);
        _sandMaterial = GetComponent<MeshRenderer> ().material;

        //new CustomRenderTexture (2048, 2048, RenderTextureFormat.ARGBFloat);

        _initMaterial = new Material (_initshader);
        RenderTexture temp = RenderTexture.GetTemporary (_splatmap.width, _splatmap.height, 0, RenderTextureFormat.ARGBFloat);
        //Graphics.Blit (_splatmap, temp);
        Graphics.Blit (temp, _splatmap, _initMaterial); //将上一帧绘制出来的splat作为这一帧的输入tex
        _sandMaterial.SetTexture ("_Splat", _splatmap);
        RenderTexture.ReleaseTemporary (temp);
        lastHitCord = Vector4.one; //one 表示null
        debugShowing = new Rect (0, 0, 256, 256);
        //temp = new RenderTexture (_splatmap.width, _splatmap.height, 0, RenderTextureFormat.ARGBFloat);
    }

    // Update is called once per frame
    void Update () {
        _drawMaterial.SetFloat ("_TrackSize", _TrackSize);
        _drawMaterial.SetFloat ("_TrackStrength", _TrackStrength);
        _sandMaterial.SetFloat ("_HeightOffset", _HeightOffset);
        // if (Input.GetKey (KeyCode.Mouse0)) {
        //     if (Physics.Raycast (_camera.ScreenPointToRay (Input.mousePosition), out _hit)) {

        //         Vector4 newHitCod = new Vector4 (_hit.textureCoord.x, _hit.textureCoord.y, 0, 0);
        //         if (newHitCod != lastHitCord) {

        //             Vector4[] test = new Vector4[2];
        //             test[0] = newHitCod;
        //             test[1] = lastHitCord;
        //             //DrawStep (test);
        //             lastHitCord = newHitCod;
        //         }

        //     }
        // } else {
        //     lastHitCord = Vector4.one; //one 表示null
        // }

    }

    public void DrawStep (Vector4 breakInf1, Vector4 breakInf2, Vector4 inersectionPoint) {
        int point_Line;
        if (breakInf2 == Vector4.zero) {
            point_Line = 1;
        } else {
            point_Line = 0;
        }
        //(item - new Vector4 (newBreakInf.x, newBreakInf.y, 0, 0)) / sampleAreaSize + new Vector4 (0.5f, 0.5f, 0, 0)

        _drawMaterial.SetVector ("_Coordinate", (breakInf1 - new Vector4 (breakInf1.x, breakInf1.y, 0, 0)) / _SampleAreaSize + new Vector4 (0.5f, 0.5f, 0, 0));
        _drawMaterial.SetVector ("_LastCoordinate", (breakInf2 - new Vector4 (breakInf1.x, breakInf1.y, 0, 0)) / _SampleAreaSize + new Vector4 (0.5f, 0.5f, 0, 0));
        Vector4 interPos = InersectionPoint (breakInf1, breakInf2);
        _drawMaterial.SetVector ("_InersectionPoint1", (interPos - new Vector4 (breakInf1.x, breakInf1.y, 0, 0)) / _SampleAreaSize + new Vector4 (0.5f, 0.5f, 0, 0));
        _drawMaterial.SetFloat ("_IsPointOrLine", point_Line);

        _sandMaterial.SetVector ("_ActorWorldPos", breakInf1);
        _sandMaterial.SetFloat ("_SampleAreaSize", _SampleAreaSize);

        //Debug.Log(coordsList.Length);

        RenderTexture temp = RenderTexture.GetTemporary (_splatmap.width, _splatmap.height, 0, RenderTextureFormat.ARGBFloat);
        Graphics.Blit (_splatmap, temp); //
        //Graphics.DrawTexture()
        Graphics.Blit (temp, _splatmap, _drawMaterial); //将上一帧绘制出来的splat作为这一帧的输入tex
        RenderTexture.ReleaseTemporary (temp);
    }

    private void OnGUI () {
        GUI.DrawTexture (debugShowing, _splatmap, ScaleMode.ScaleToFit, false, 1);
    }

    public Vector4 InersectionPoint (Vector4 tangentPoint1, Vector4 tangentPoint2) {
        float tangent1 = tangentPoint1.w / tangentPoint1.z;
        float tangent2 = tangentPoint2.w / tangentPoint2.z;
        float x = (tangentPoint2.y - tangentPoint1.y + tangent1 * tangentPoint1.x - tangent2 * tangentPoint2.x) / (tangent1 - tangent2);
        float y = (tangent1 * tangentPoint2.y - tangent2 * tangentPoint1.y + tangent1 * tangent2 * (tangentPoint1.x - tangentPoint2.x)) / (tangent1 - tangent2);
        return new Vector4 (x, y, 0, 0);
    }
}