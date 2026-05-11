#ifndef BEZIER_INCLUDED
#define BEZIER_INCLUDED


float3 QuinticBezierCurve(float3 p1, float3 p2, float3 p3, float p4, float t)
{
	// Optimized formula from :
	// https://denisrizov.com/2016/06/02/bezier-curves-unity-package-included/

	float3 p0 = float3(0, 0, 0);

	float u = 1 - t;
	float t2 = t * t;
	float u2 = u * u;
	float u3 = u2 * u;
	float t3 = t2 * t;
	float u4 = u3 * u;
	float t4 = t3 * t;

	float3 result =
		(u4)*p0 +
		(4 * u3 * t) * p1 +
		(4 * u2 * t2) * p2 +
		(4 * u * t3) * p3 +
		(t4)*p4;

	/* (1-t)4 * p0 + 
	(4 * t) * (1-t)3 * p1 +
	(4 * t2) * (1-t)2 * p2 +
	(4 * t3) * (1-t) * p3 +
	(t4) * p4
	*/ 

	return result;
}

float3 QuadraticBezierCurve(float3 p1, float3 p2, float3 p3, float t)
{
	float3 p0 = float3(0, 0, 0);

	float u = 1 - t;
	float t2 = t * t;
	float u2 = u * u;
	float u3 = u2 * u;
	float t3 = t2 * t;

	float3 result =
		(u3)*p0 +
		(3 * u2 * t) * p1 +
		(3 * u * t2) * p2 +
		(t3)*p3;

	return result;
}

float3 TrigonometricBezierCurve(float3 p1, float3 p2, float t)
{
	float3 p0 = float3(0, 0, 0);

	float u = 1 - t;
	float t2 = t * t;
	float u2 = u * u;

	float3 result =
		(u2)*p0 +
		(2 * u * t) * p1 +
		t2 * p2;

	return result;
}
#endif