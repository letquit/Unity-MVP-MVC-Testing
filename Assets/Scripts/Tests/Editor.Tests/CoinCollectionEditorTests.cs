using System;
using System.Collections;
using System.Collections.Generic;
using Architecture;
using NSubstitute;
using NUnit.Framework;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.TestTools;
using UnityUtils;

public class CoinCollectionEditorTests
{
    [Test]
    public void CoinCollectionEditorTestsSimplePasses()
    {
        // 1st level Is/Has/Does/Contains
        // 2dn level All/Not/Some/Exactly
        // Or/And/Not
        // Is.Unique / Is.Ordered
        // Assert.IsTrue
        string username = "User123";
        Assert.That(username, Does.StartWith("U"));
        Assert.That(username, Does.EndWith("3"));
        
        var list = new List<int> { 1, 2, 3, 4, 5 };
        Assert.That(list, Contains.Item(3));
        Assert.That(list, Is.All.Positive);
        Assert.That(list, Has.Exactly(2).LessThan(3));
        Assert.That(list, Is.Ordered);
        Assert.That(list, Is.Unique);
        Assert.That(list, Has.Exactly(3).Matches<int>(NumberPredicates.IsOdd));
    }

    private ICoinController controller;
    private ICoinView view;
    private ICoinModel model;
    private ICoinService service;

    [SetUp]
    public void SetUp()
    {
        view = Substitute.For<ICoinView>();
        service = Substitute.For<ICoinService>();
        model = Substitute.For<ICoinModel>();
        
        Assert.That(view, Is.Not.Null);
        Assert.That(service, Is.Not.Null);
        Assert.That(model, Is.Not.Null);

        model.Coins.Returns(new Observable<int>(0));
        
        Assert.That(model.Coins, Is.Not.Null);
        Assert.That(model, Has.Property("Coins").Not.Null);
        
        service.Load().Returns(model);
        controller = new CoinController.Builder().WithService(service).Build(view);
        
        Assert.That(controller, Is.Not.Null);
    }

    [TearDown]
    public void TearDown() { }
    
    [Test]
    public void CoinControllerBuilder_Build_ShouldThrowArgumentNullException_WhenViewIsNull()
    {
        Assert.That(() => new CoinController.Builder().Build(null), Throws.ArgumentNullException);
        // Assert.Throws<ArgumentNullException>(() => new CoinController().Builder().Build(null))
    }
    
    [Test]
    public void CoinControllerBuilder_Build_ShouldThrowArgumentNullException_WhenServiceIsNull()
    {
        Assert.That(
            () => new CoinController.Builder().WithService(null).Build(view),
            Throws.ArgumentNullException
        );
    }

    [Test]
    public void UpdateView_ShouldUpdateCoinsDisplay_WhenCoinsAreCollected()
    {
        controller.Collect(1);
        view.Received().UpdateCoinsDisplay(1);
    }

    [TestCase(5, 5, 10)]
    [TestCase(0, 5, 5)]
    [TestCase(0, 0, 0)]
    public void Collect_ShouldAddCoins_WhenCalledWithAPositiveNumber(int initialCoins, int coinsToAdd,
        int expectedCoins)
    {
        model.Coins.Returns(new Observable<int>(initialCoins));
        
        controller.Collect(coinsToAdd);
        Assert.That(model.Coins.Value, Is.EqualTo(expectedCoins));
    }
}

public static class NumberPredicates
{
    public static bool IsEven(int x)
    {
        return x % 2 == 0;
    }
    
    public static bool IsOdd(int x)
    {
        return x % 2 != 0;
    }
}
