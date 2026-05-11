using System;
using UnityUtils;

namespace Architecture
{
    public interface ICoinModel
    {
        Observable<int> Coins { get; }

        CoinData Serialize();
        void Deserialize(CoinData savedData);
    }
    
    public class CoinModel : ICoinModel
    {
        public Observable<int> Coins { get; } = new Observable<int>(0);

        public CoinData Serialize()
        {
            return new CoinData { coins = Coins.Value };
        }

        public void Deserialize(CoinData savedData)
        {
            Coins.Set(savedData.coins);
        }
    }

    [Serializable]
    public struct CoinData
    {
        public int coins;
    }
}