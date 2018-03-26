using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SurfaceBreaker_Center : MonoBehaviour {
    public float _SampleAreaSize;
    // Use this for initialization
    private Queue<Vector4> BreakInfList;
    private Vector2 _prevDrawPos;
    public float drawDelta;
    void Start () {
        BreakInfList = new Queue<Vector4> ();
        drawDelta = 0.005f;
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
                BreakInfList.Enqueue (newBreakInf);

                if (BreakInfList.Count > 3) {
                    BreakInfList.Dequeue ();
                }
                List<Vector4> CoordList = new List<Vector4> ();
                foreach (var item in BreakInfList) {
                    CoordList.Add ((item - new Vector4 (newBreakInf.x, newBreakInf.y, 0, 0)) / _SampleAreaSize + new Vector4 (0.5f, 0.5f, 0, 0));
                }
                CoordList.Reverse ();
                texDraw.DrawStep (CoordList.ToArray (), newBreakInf);
                
                //  Debug.Log(CoordsList.Count);

            }
        }
    }
}