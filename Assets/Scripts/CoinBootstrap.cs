using Architecture;
using UnityEngine;

public class CoinBootstrap : MonoBehaviour
{
    public CoinCounterView view;

    private ICoinController controller;

    private void Awake()
    {
        var service = new CoinServiceMemory();
        controller = new CoinController.Builder()
            .WithService(service)
            .Build(view);
    }
}