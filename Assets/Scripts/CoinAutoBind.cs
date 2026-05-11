using Architecture;
using UnityEngine;

public class CoinAutoBind : MonoBehaviour
{
    public CoinCounterView view;

    private void Awake()
    {
        var controller = new CoinController.Builder()
            .WithService(new CoinServiceMemory())
            .Build(view);

        foreach (var coin in FindObjectsOfType<CoinComponent>())
        {
            coin.controller = controller;
        }
    }
}