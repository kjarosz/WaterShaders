using UnityEngine;
using System.Collections;

public class Meshuga : MonoBehaviour {
    public Vector3[] newVertices;
    public int[] newTriangles;
    public Vector2[] newUV;

	void Start () {
        Mesh mesh = new Mesh();
        GetComponent<MeshFilter>().mesh = mesh;
        GetComponent<MeshCollider>().sharedMesh = mesh;
        makeVertices();
        mesh.vertices = newVertices;
        mesh.triangles = newTriangles;
        mesh.uv = newUV;
	}

    void makeVertices()
    {
        int n = 150;
        int tCount = triangleCount(n) * 3;

        newVertices = new Vector3[n*n];
        newTriangles = new int[tCount];
        newUV = new Vector2[newVertices.Length];

        float vertexGap = 0.05f;
        float width = n * vertexGap;
        float height = n * vertexGap;

        float halfWidth = width / 2.0f;
        float halfHeight = height / 2.0f;

        int t = 0;
        for(int x = 0; x < n; x++)
        {
            for(int z = 0; z < n; z++)
            {
                int i = x * n + z;
                newVertices[i] = new Vector3(x*.065f - halfWidth, 0.0f, z*.065f - halfHeight);
                newUV[i] = new Vector2(newVertices[i].x, newVertices[i].z);

                if (x < n - 1 && z < n - 1)
                {
                    newTriangles[t] = i;
                    newTriangles[t + 1] = i + 1;
                    newTriangles[t + 2] = i + n + 1;

                    newTriangles[t + 3] = i;
                    newTriangles[t + 4] = i + n + 1;
                    newTriangles[t + 5] = i + n;

                    t += 6;
                }
            }
        }

        Debug.Log(tCount);
        Debug.Log(t);
    }

    int triangleCount(int n)
    {
        int total = 0;
        while (n > 1)
            total += 2 + 4 * ((n--) - 2);
        return total;
    }
}
