﻿using UnityEngine;

[RequireComponent(typeof(Camera))]
public class FreeRoamCamera : MonoBehaviour
{
	private float _currentSpeed;
	private bool _moving;
	private bool _togglePressed;

	public bool AllowMovement = true;
	public bool AllowRotation = true;
	public KeyCode BackwardButton = KeyCode.S;

	public float CursorSensitivity = 0.01f;

	public KeyCode ForwardButton = KeyCode.W;
	public float IncreaseSpeed = 5f;
	public float InitialSpeed = 20f;
	public KeyCode LeftButton = KeyCode.A;
	public KeyCode RightButton = KeyCode.D;

	private void Update()
	{
		if (AllowMovement)
		{
			var lastMoving = _moving;
			var deltaPosition = Vector3.zero;

			if (_moving)
				_currentSpeed += IncreaseSpeed * Time.deltaTime;

			_moving = false;

			CheckMove(ForwardButton, ref deltaPosition, transform.forward);
			CheckMove(BackwardButton, ref deltaPosition, -transform.forward);
			CheckMove(RightButton, ref deltaPosition, transform.right);
			CheckMove(LeftButton, ref deltaPosition, -transform.right);

			if (_moving)
			{
				if (_moving != lastMoving)
					_currentSpeed = InitialSpeed;

				transform.position += deltaPosition * _currentSpeed * Time.deltaTime;
			} else
			{
				_currentSpeed = 0f;
			}
		}

		if (Input.GetMouseButton(0) && AllowRotation)
		{
			Cursor.visible = false;
			var eulerAngles = transform.eulerAngles;
			eulerAngles.x += -Input.GetAxis("Mouse Y") * 359f * CursorSensitivity;
			eulerAngles.y += Input.GetAxis("Mouse X") * 359f * CursorSensitivity;
			if (eulerAngles.x < 89 || eulerAngles.x > 271) transform.eulerAngles = eulerAngles;
		} else
		{
			Cursor.visible = true;
		}
	}

	private void CheckMove(KeyCode keyCode, ref Vector3 deltaPosition, Vector3 directionVector)
	{
		if (Input.GetKey(keyCode))
		{
			_moving = true;
			deltaPosition += directionVector;
		}
	}
}