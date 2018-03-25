using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SurfaceBreaker : MonoBehaviour {

    // Use this for initialization
    private Queue<Vector4> CoordsList;
    private Vector2 _prevDrawPos;
    public float drawDelta;
    void Start () {
        CoordsList = new Queue<Vector4> ();
        drawDelta = 0.005f;
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
            Vector2 tmpVelct2D = (new Vector2 (tmpVelct.x, tmpVelct.z)).normalized;
            Vector2 tmpPos2D = new Vector2 (hit.textureCoord.x, hit.textureCoord.y);
            Vector4 cord1 = new Vector4 (tmpPos2D.x, tmpPos2D.y, tmpVelct2D.x, tmpVelct2D.y);

            if (Vector2.Distance (_prevDrawPos, tmpPos2D) >= drawDelta) {

                _prevDrawPos = tmpPos2D;
                CoordsList.Enqueue (cord1);

                if (CoordsList.Count > 3) {
                    CoordsList.Dequeue ();
                }
                //texDraw.DrawStep (CoordsList.ToArray ());
                //  Debug.Log(CoordsList.Count);

            }
        }
    }
}