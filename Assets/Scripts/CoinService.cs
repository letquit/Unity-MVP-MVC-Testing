namespace Architecture
{
    public interface ICoinService
    {
        void Save(ICoinModel model);
        ICoinModel Load();
    }
}