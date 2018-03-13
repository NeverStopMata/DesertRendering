using UnityEngine;

namespace Complete
{
    public class CameraControl : MonoBehaviour
    {
        public float m_DampTime = 0.2f;                 // Approximate time for the camera to refocus.
        public float m_ScreenEdgeBuffer = 4f;           // Space between the top/bottom most target and the screen edge.
        public float m_MinSize = 6.5f;                  // The smallest orthographic size the camera can be.
        [HideInInspector] public Transform[] m_Targets; // All the targets the camera needs to encompass.

        public float sensitivity = 10f;
        public float maxYAngle = 80f;
        private Vector2 currentRotation;
       // private Camera m_Camera;                        // Used for referencing the camera.
        private float m_ZoomSpeed;                      // Reference speed for the smooth damping of the orthographic size.
        private Vector3 m_MoveVelocity;                 // Reference velocity for the smooth damping of the position.
        private float moveSpeed = 10.0f;
       // private float rotationSpeed = 5.0f;


        // private void Awake()
        // {
        //     m_Camera = GetComponentInChildren<Camera>();
        // }


        private void FixedUpdate()
        {
            // Move the camera towards a desired position.
            Move();
            transform.GetChild(1).transform.SetPositionAndRotation(new Vector3(transform.position.x, 15, transform.position.z), new Quaternion(0, 0, 0, 1));

        }


        private void Move()
        {
            if (Input.GetKey("d"))
            {
                transform.position += transform.right * moveSpeed * Time.deltaTime;
            }
            if (Input.GetKey("a"))
            {
                transform.position -= transform.right * moveSpeed * Time.deltaTime;
            }
            if (Input.GetKey("w"))
            {
                transform.position += transform.forward * moveSpeed * Time.deltaTime;
            }
            if (Input.GetKey("s"))
            {
                transform.position -= transform.forward * moveSpeed * Time.deltaTime;
            }
            //// Find the average position of the targets.
            currentRotation.x += Input.GetAxis("Mouse X") * sensitivity;
            currentRotation.y -= Input.GetAxis("Mouse Y") * sensitivity;
            currentRotation.x = Mathf.Repeat(currentRotation.x, 360);
            currentRotation.y = Mathf.Clamp(currentRotation.y, -maxYAngle, maxYAngle);
            transform.rotation = Quaternion.Euler(currentRotation.y, currentRotation.x, 0);
            //// Smoothly transition to that position.
            if (Input.GetMouseButtonDown(1))
             Cursor.lockState = CursorLockMode.Locked;

        }






    }
}