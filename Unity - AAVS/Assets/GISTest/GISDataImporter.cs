using System.Collections.Generic;
using UnityEngine;
using SimpleJSON;

public class GISDataImporter : MonoBehaviour
{
    public TextAsset buildingGeoJsonFile;
    public TextAsset roadGeoJsonFile;
    public Material residentialMaterial;
    public Material workMaterial;
    public Material universityMaterial;
    public Material entertainmentMaterial;
    public Material churchMaterial;
    public Material defaultRoadMaterial;
    public Material railMaterial;
    public Material tramwayMaterial;
    public Vector3 scale = new Vector3(1, 1, 1);
    public Vector3 positionOffset = new Vector3(0, 0, 0);

    void Start()
    {
        ImportGeoJsonData(buildingGeoJsonFile, true);
        ImportGeoJsonData(roadGeoJsonFile, false);
    }

    void ImportGeoJsonData(TextAsset geoJsonFile, bool isBuilding)
    {
        var geoJsonData = JSON.Parse(geoJsonFile.text);
        var features = geoJsonData["features"].AsArray;

        Debug.Log("Number of features: " + features.Count);

        foreach (JSONNode feature in features)
        {
            var geometryType = feature["geometry"]["type"].Value;
            var coordinates = feature["geometry"]["coordinates"].AsArray;
            var properties = feature["properties"];

            if (isBuilding)
            {
                switch (geometryType)
                {
                    case "MultiPolygon":
                        CreateMultiPolygon(coordinates, properties);
                        break;
                    // Add other geometry types if needed
                }
            }
            else
            {
                switch (geometryType)
                {
                    case "MultiLineString":
                        CreateMultiLineString(coordinates, properties);
                        break;
                    // Add other geometry types if needed
                }
            }

            Debug.Log("Feature properties: " + properties.ToString());
        }
    }

    void CreateMultiPolygon(JSONArray coordinates, JSONNode properties)
    {
        foreach (JSONNode polygon in coordinates)
        {
            foreach (JSONNode ring in polygon.AsArray)
            {
                List<Vector3> vertices = new List<Vector3>();
                foreach (JSONNode point in ring.AsArray)
                {
                    float lon = point[0].AsFloat;
                    float lat = point[1].AsFloat;
                    vertices.Add(new Vector3(lon, 0, lat)); // Adjust conversion as necessary
                }
                CreatePolygon(vertices, properties);
            }
        }
    }

    void CreateMultiLineString(JSONArray coordinates, JSONNode properties)
    {
        foreach (JSONNode line in coordinates)
        {
            List<Vector3> vertices = new List<Vector3>();
            foreach (JSONNode point in line.AsArray)
            {
                float lon = point[0].AsFloat;
                float lat = point[1].AsFloat;
                vertices.Add(new Vector3(lon, 0, lat)); // Adjust conversion as necessary
            }
            CreateLine(vertices, properties);
        }
    }

    void CreatePolygon(List<Vector3> vertices, JSONNode properties)
    {
        GameObject polygon = new GameObject(properties["name"] != null ? properties["name"].Value : "Polygon");
        MeshFilter mf = polygon.AddComponent<MeshFilter>();
        MeshRenderer mr = polygon.AddComponent<MeshRenderer>();

        Mesh mesh = new Mesh();
        mf.mesh = mesh;

        mesh.vertices = vertices.ToArray();
        List<int> triangles = new List<int>();
        for (int i = 1; i < vertices.Count - 1; i++)
        {
            triangles.Add(0);
            triangles.Add(i);
            triangles.Add(i + 1);
        }
        mesh.triangles = triangles.ToArray();

        mesh.RecalculateNormals();

        // Set the material based on the building type
        string type = properties["type"] != null ? properties["type"].Value : "residential";
        switch (type)
        {
            case "work":
                mr.material = workMaterial;
                break;
            case "university":
                mr.material = universityMaterial;
                break;
            case "entertainment":
                mr.material = entertainmentMaterial;
                break;
            case "church":
                mr.material = churchMaterial;
                break;
            case "residential":
            default:
                mr.material = residentialMaterial;
                break;
        }

        // Apply scaling and position offset
        polygon.transform.localScale = scale;
        polygon.transform.position = positionOffset;
    }

    void CreateLine(List<Vector3> vertices, JSONNode properties)
    {
        GameObject road = new GameObject(properties["name"] != null ? properties["name"].Value : "Road");
        LineRenderer lr = road.AddComponent<LineRenderer>();
        
        lr.positionCount = vertices.Count;
        lr.SetPositions(vertices.ToArray());

        lr.startWidth = 0.1f;
        lr.endWidth = 0.1f;
        lr.useWorldSpace = false;

        // Set the material based on the road type
        string type = properties["railway"] != null ? properties["railway"].Value : properties["highway"] != null ? properties["highway"].Value : "road";
        switch (type)
        {
            case "rail":
                lr.material = railMaterial;
                break;
            case "tram":
                lr.material = tramwayMaterial;
                break;
            case "road":
            default:
                lr.material = defaultRoadMaterial;
                break;
        }

        // Apply scaling and position offset
        road.transform.localScale = scale;
        road.transform.position = positionOffset;
    }
}