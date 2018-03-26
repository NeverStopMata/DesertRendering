using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SurfaceBreaker_Center : MonoBehaviour {
    public GameObject surface;
    // Use this for initialization
    //private Queue<Vector4> BreakInfList;

    private Vector4 BreakInf1;
    private Vector4 BreakInf2;
    private Vector2 _prevDrawPos;
    private float sampleAreaSize;
    public float drawDelta;
    void Start () {
        //BreakInfList = new Queue<Vector4> ();
        drawDelta = 0.005f;
        sampleAreaSize = surface.GetComponent<SurfaceTrackController>()._SampleAreaSize;
        BreakInf1 = Vector4.zero;
        BreakInf2 = Vector4.zero;

        //_SampleAreaSize = 1.0f;
    }

    // Update is called once per frame
    void Update () {
        float v = Input.GetAxis ("Vertical");
        float h = Input.GetAxis ("Horizontal");

        GetComponent<Rigidbody> ().AddTorque (v * 40, 0, -h * 40);

        //if (Vector3.Distance(_prevDrawPos, transform.position) < drawDelta)
        //    return;

        //_prevDrawPos = transform.position;

        //Debug.DrawLine(transform.position, transform.position + Vector3.down);

        RaycastHit hit;
        if (Physics.Raycast (transform.position, Vector3.down, out hit)) {
            var texDraw = hit.collider.gameObject.GetComponent<SurfaceTrackController> ();
            if (texDraw == null)
                return;
            var tmpVelct = GetComponent<Rigidbody> ().velocity;
            Vector2 tmpVelct2D = new Vector2 (tmpVelct.x, tmpVelct.z);
            //Vector2 tmpPos2D = new Vector2(hit.textureCoord.x, hit.textureCoord.y);
            Vector2 tmpPos2D = new Vector2 (transform.position.x, transform.position.z);
            Vector4 newBreakInf = new Vector4 (transform.position.x, transform.position.z, tmpVelct2D.x, tmpVelct2D.y);

            if (Vector2.Distance (_prevDrawPos, tmpPos2D) >= drawDelta) {

                _prevDrawPos = tmpPos2D;
                BreakInf2 = BreakInf1;
                BreakInf1 = newBreakInf;
                //BreakInfList.Enqueue (newBreakInf);

                texDraw.DrawStep (BreakInf1, BreakInf2,Vector4.zero);
                
                //  Debug.Log(CoordsList.Count);

            }
        }
    }
}