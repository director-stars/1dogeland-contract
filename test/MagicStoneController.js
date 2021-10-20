const { BN, ether, balance } = require('openzeppelin-test-helpers');

const CryptoDogeManager = artifacts.require('CryptoDogeManager')
const CryptoDogeController = artifacts.require('CryptoDogeController');
const CryptoDogeNFT = artifacts.require('CryptoDogeNFT')
const MagicStoneNFT = artifacts.require('MagicStoneNFT')
const MarketController = artifacts.require('MarketController')
const MagicStoneController = artifacts.require('MagicStoneController')
const ForceSend = artifacts.require('ForceSend');
const oneDogeABI = require('./abi/oneDoge');

const oneDogeAddress = '0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56';
const oneDogeContract = new web3.eth.Contract(oneDogeABI, oneDogeAddress);
const oneDogeOwner = '0x8c7de13ecf6e92e249696defed7aa81e9c93931a';

contract('test CryptoDogeManager', async([alice, bob, admin, dev, minter]) => {

    before(async () => {
        this.cryptoDogeManager = await CryptoDogeManager.new(
            {
                from: alice
            });
            
        this.cryptoDogeNFT = await CryptoDogeNFT.new(
            'CryptoDogeNFT',
            'CryptoDogeNFT',
            this.cryptoDogeManager.address,
            oneDogeAddress,
        {
            from: alice
        });

        this.magicStoneNFT = await MagicStoneNFT.new(
            'MagicStoneNFT',
            'MagicStoneNFT',
            this.cryptoDogeManager.address,
        {
            from: alice
        });

        this.cryptoDogeController = await CryptoDogeController.new({ from: alice });

        // this.createCryptoDoge = await CreateCryptoDoge.new({ from: alice });
        
        this.marketController = await MarketController.new({ from: alice });

        this.magicStoneController = await MagicStoneController.new({ from: alice });
    });

    it('manager test', async() => {
        
        await this.cryptoDogeManager.addBattlefields(this.cryptoDogeController.address);
        await this.cryptoDogeManager.addMarkets(this.cryptoDogeNFT.address);
        await this.cryptoDogeManager.setFeeAddress(this.cryptoDogeController.address);
        // await this.cryptoDogeManager.addEvolvers(this.cryptoDogeNFT.address);
        await this.cryptoDogeController.setCryptoDogeNFT(this.cryptoDogeNFT.address);
        await this.cryptoDogeController.setMagicStoneNFT(this.magicStoneNFT.address);

        await this.cryptoDogeManager.addEvolvers(this.cryptoDogeController.address);
        // await this.createCryptoDoge.setCryptoDogeNFT(this.cryptoDogeNFT.address);
        // await this.createCryptoDoge.setManager(this.cryptoDogeManager.address);

        await this.marketController.setCryptoDogeNFT(this.cryptoDogeNFT.address);
        await this.marketController.setCryptoDogeController(this.cryptoDogeController.address);

        await this.cryptoDogeManager.addEvolvers(this.magicStoneController.address);
        await this.cryptoDogeManager.addBattlefields(this.magicStoneController.address);
        await this.magicStoneController.setCryptoDogeNFT(this.cryptoDogeNFT.address);
        await this.magicStoneController.setCryptoDogeController(this.cryptoDogeController.address);
        await this.magicStoneController.setMagicStoneNFT(this.magicStoneNFT.address);

        console.log(await this.cryptoDogeController.cryptoDogeNFT());

        const forceSend = await ForceSend.new();
        await forceSend.go(oneDogeOwner, { value: ether('1') });

        console.log('balance of oneDogeOwner: ', await oneDogeContract.methods.balanceOf(oneDogeOwner).call());
        
        await oneDogeContract.methods.transfer(alice, '100000000000000000000').send({ from: oneDogeOwner});
        // await oneDogeContract.methods.transfer(admin, '100000000000000000000').send({ from: oneDogeOwner});

        await oneDogeContract.methods.transfer(this.cryptoDogeController.address, '100000000000000000000').send({ from: oneDogeOwner});
        
        console.log('test');
        let priceDoge = await this.cryptoDogeNFT.priceDoge();
        console.log('priceDoge', priceDoge);

        let tribe = Math.floor(Math.random() * 4);
        console.log('tribe', tribe);
        // console.log(this.cryptoDogeController.address)
        await oneDogeContract.methods.approve(this.cryptoDogeController.address, priceDoge).send({ from : alice});
        let Doge = await this.cryptoDogeController.buyDoge([tribe], bob, { from : alice });
        // await oneDogeContract.methods.approve(this.cryptoDogeController.address, priceDoge).send({ from : admin});
        // await this.cryptoDogeController.buyDoge([tribe], bob, { from : admin });
        // console.log(Doge.logs[0].args);
        let cryptoDoges = await this.cryptoDogeNFT.balanceOf(alice);
        // let cryptoDoges_1 = await this.cryptoDogeNFT.balanceOf(admin);
        
        console.log('cryptoDoges', cryptoDoges.toString());
        let tokenId = await this.cryptoDogeNFT.tokenOfOwnerByIndex(alice, parseInt(cryptoDoges.toString())-1);
        // let tokenId_1 = await this.cryptoDogeNFT.tokenOfOwnerByIndex(admin, parseInt(cryptoDoges_1.toString())-1);
        await this.cryptoDogeController.setDNA(tokenId, { from : alice });
        // await this.cryptoDogeController.setDNA(tokenId_1, { from : admin });
        console.log(parseInt(tokenId.toString()));

        // let balance_A = await oneDogeContract.methods.balanceOf(alice).call();

        // console.log('balance_A', await balance_A.toString());
        
        let result = await this.cryptoDogeController.fight(tokenId, alice, 0, false);
        // console.log(result);
        // let claimTokenAmount = await this.cryptoDogeNFT.getClaimTokenAmount(alice);
        // console.log('claimTokenAmount', claimTokenAmount.toString());

        // await this.cryptoDogeController.claimToken({from: alice});

        // balance_A = await oneDogeContract.methods.balanceOf(alice).call();

        // console.log('balance_B', balance_A.toString());

        // result = await this.cryptoDogeController.fight(tokenId, alice, 0, true);

        // console.log(result)

        // console.log('alice', alice)
        // console.log(await this.cryptoDogeNFT.ownerOf(tokenId));

        // await this.cryptoDogeNFT.placeOrder(tokenId, 1000, {from: alice});
        // await this.cryptoDogeNFT.placeOrder(tokenId_1, 1000, {from: admin});
        // console.log('result-----------')
        // result = await this.marketController.getDogeOfSaleByOwner({from: alice});
        // console.log('result', result);
        // result = await this.marketController.getDogeOfSale();
        // console.log('result', result);
        // result = await this.marketController.getDogeByOwner({from: alice});


        // const referral_balance = await oneDogeContract.methods.balanceOf(bob).call();
        // console.log(referral_balance.toString());
//////////////////////////////////////////////////test--stone////////////////////////////////////////
        let priceStone = await this.magicStoneNFT.priceStone();
        console.log('priceStone', priceStone);
        await oneDogeContract.methods.approve(this.magicStoneController.address, priceStone).send({ from : alice});
        // let owner = await this.cryptoDogeNFT.ownerOf(tokenId);
        // console.log(owner);
        // console.log(alice);
        await this.magicStoneController.buyStone({from: alice, value: priceStone});

        await this.magicStoneController.setAutoFight(tokenId, 1, 0, { from : alice});
        result = await this.magicStoneController.getAutoFightResults(tokenId, {from: alice});
        console.log(result.logs[0].args);

        // result = await this.cryptoDogeNFT.fillOrder(tokenId, bob, {from: admin});
        console.log('////////////////////////');
    })
})