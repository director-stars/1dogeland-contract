const { BN, ether, balance } = require('openzeppelin-test-helpers');

const CryptoDogeManager = artifacts.require('CryptoDogeManager')
const CryptoDogeController = artifacts.require('CryptoDogeController');
const CryptoDogeNFT = artifacts.require('CryptoDogeNFT')
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

        this.cryptoDogeController = await CryptoDogeController.new({ from: alice });
        
    });

    it('manager test', async() => {
        

        await this.cryptoDogeManager.addEvolvers(this.cryptoDogeController.address);
        await this.cryptoDogeManager.addBattlefields(this.cryptoDogeController.address);
        await this.cryptoDogeManager.addFarmOwners(this.cryptoDogeController.address);

        await this.cryptoDogeController.setCryptoDogeNFT(this.cryptoDogeNFT.address);

        const forceSend = await ForceSend.new();
        await forceSend.go(oneDogeOwner, { value: ether('1') });

        console.log('balance of oneDogeOwner: ', await oneDogeContract.methods.balanceOf(oneDogeOwner).call());
        
        await oneDogeContract.methods.transfer(alice, '100000000000000000000').send({ from: oneDogeOwner});

        await oneDogeContract.methods.transfer(this.cryptoDogeController.address, '100000000000000000000').send({ from: oneDogeOwner});
        
        console.log('test');
        let priceEgg = await this.cryptoDogeNFT.priceEgg();
        // console.log('priceEgg', priceEgg);

        let tribe = Math.floor(Math.random() * 4);
        console.log('tribe', tribe);
        console.log(this.cryptoDogeController.address)
        await oneDogeContract.methods.approve(this.cryptoDogeController.address, priceEgg).send({ from : alice});
        let egg = await this.cryptoDogeController.buyEgg([tribe], { from : alice });
        console.log(egg.logs[0].args);
        let cryptoDoges = await this.cryptoDogeNFT.balanceOf(alice);
        
        console.log('cryptoDoges', cryptoDoges.toString());
        let tokenId = await this.cryptoDogeNFT.tokenOfOwnerByIndex(alice, parseInt(cryptoDoges.toString())-1);
        console.log(parseInt(tokenId.toString()));

        let balance_A = await oneDogeContract.methods.balanceOf(alice).call();

        console.log('balance_A', await balance_A.toString());
        
        let result = await this.cryptoDogeController.fight(tokenId, alice, 90);
        console.log(result);
        let claimTokenAmount = await this.cryptoDogeController.claimTokenAmount(alice);
        console.log('claimTokenAmount', claimTokenAmount.toString());

        await this.cryptoDogeController.claimToken({from: alice});

        balance_A = await oneDogeContract.methods.balanceOf(alice).call();

        console.log('balance_B', balance_A.toString());

        result = await this.cryptoDogeController.fight(tokenId, alice, 90);

        console.log(result)

        // xbusd = ;
        // console.log(dna.toString());
    
        // for(let i = 0; i < cryptoDoges; i ++){
        //     let tokenId = await this.cryptoDogeNFT.tokenOfOwnerByIndex(alice, i);
        //     let dogeInfo = await this.cryptoDogeNFT.getdoger(tokenId);
        // }
    })
})