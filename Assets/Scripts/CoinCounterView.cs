using Architecture;
using TMPro;
using UnityEngine;

public class CoinCounterView : MonoBehaviour, ICoinView
{
    public TextMeshProUGUI label;

    public void UpdateCoinsDisplay(int coins)
    {
        if (label != null)
            label.text = "Coins:" + coins.ToString();
    }
}