using Architecture;

public class CoinServiceMemory : ICoinService
{
    private ICoinModel cached;

    public void Save(ICoinModel model)
    {
        cached = model;
    }

    public ICoinModel Load()
    {
        return cached ?? new CoinModel();
    }
}