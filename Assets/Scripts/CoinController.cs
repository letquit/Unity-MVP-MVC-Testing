using UnityUtils;

namespace Architecture
{
    public interface ICoinController
    {
        void Collect(int coins);
        void UpdateView(int coins);

        void Save();
        ICoinModel Load();
    }

    public class CoinController : ICoinController
    {
        private readonly ICoinModel model;
        private readonly ICoinView view;
        private readonly ICoinService service;

        public CoinController(ICoinView view, ICoinService service)
        {
            Preconditions.CheckNotNull(view, "CoinView cannot be null");
            Preconditions.CheckNotNull(service, "CoinService cannot be null");
            
            this.view = view;
            this.service = service;

            model = Load();
            model.Coins.AddListener(UpdateView);
            model.Coins.Invoke();
        }

        public void Collect(int coins) => model.Coins.Set(model.Coins.Value + coins);

        public void UpdateView(int coins) => view.UpdateCoinsDisplay(coins);

        public void Save() => service.Save(model);

        public ICoinModel Load() => service.Load();

        #region Builder
        public class Builder
        {
            private ICoinService service;

            public Builder WithService(ICoinService service)
            {
                this.service = Preconditions.CheckNotNull(service, "CoinService cannot be null");
                return this;
            }

            public ICoinController Build(ICoinView view)
            {
                Preconditions.CheckNotNull(view, "CoinView cannot be null");
                Preconditions.CheckNotNull(service, "CoinService cannot be null");
                return new CoinController(view, service);
            }
        }
        #endregion
    }
}