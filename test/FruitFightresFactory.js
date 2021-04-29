const FruitFightersFactory = artifacts.require("FruitFightersFactory");
const fighterNames = ["King", "Qeen", "Rocky"];

async function shouldThrow(promise) {
    try {
        await promise;
        assert(true);
    } catch (err) {
        return;
    }
    assert(false, "The contract did not throw.");   
}    

contract("FruitFightersFactory", (accounts) => {
    let [alice, bob] = accounts;
    let contractInstance;

    beforeEach(async () => {
        contractInstance = await FruitFightersFactory.new();
    })
    
    it("should be able to create a new fancy fighter", async () => {
        const result = await contractInstance.createFancyFruitFighter(fighterNames[0], {from: alice});

        assert.equal(result.receipt.status, true);
        assert.equal(result.logs[0].args.name, fighterNames[0]);
       
    });
    

    it("should be able to create a new rare fighter", async () => {
        const result = await contractInstance.createRareFruitFighter(fighterNames[0], {
            from: alice, 
            value: web3.utils.toWei('0.5', 'ether')
        });
        
        assert.equal(result.receipt.status, true);
        assert.equal(result.logs[0].args.name, fighterNames[0]);
        
    });

    it("should be able to check if name is free", async () => {
        await contractInstance.createFancyFruitFighter(fighterNames[0], {from: alice});
        const isFirstNameFree = await contractInstance.isNameFree(fighterNames[0], {from: alice});
        const isSecondNameFree = await contractInstance.isNameFree(fighterNames[1], {from: alice});
        assert.equal(isFirstNameFree, false);
        assert.equal(isSecondNameFree, true);
    });

    it("should allow to change name", async () => {
        const createFersult = await contractInstance.createFancyFruitFighter(fighterNames[0], {from: alice});
        const tokenId = createFersult.logs[0].args.id;
        const result = await contractInstance.changeName(tokenId, fighterNames[1], {
            from: alice,
            value: web3.utils.toWei('0.01', 'ether')
        });

        assert.equal(result.logs[0].args.name, fighterNames[1]);
    });


    it("should not allow two fighters with same name", async () => {
        contractInstance.createFancyFruitFighter(fighterNames[0], {from: alice});
        await shouldThrow(contractInstance.createFancyFruitFighter(fighterNames[0], {from: alice}));
    });

    it("should not allow to create exclusive fruit fighters not from behalf contract owner", async () => {
        await shouldThrow(contractInstance.createExclusiveFruitFighter(fighterNames[0], {from: bob}));
    });

    it("should allow to create exclusive fruit fighters from owner", async () => {
        const result = await contractInstance.createExclusiveFruitFighter(fighterNames[0], {from: alice});
        assert.equal(result.logs[0].args.tokenType.toNumber(), 3);
    });
            
})
