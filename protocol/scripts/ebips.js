const fs = require('fs')
const { getBeanstalk, impersonateBeanstalkOwner, mintEth } = require("../utils")

async function ebip6(mock = true, account = undefined) {
    if (account == undefined) {
        account = await impersonateBeanstalkOwner()
        await mintEth(account.address)
    }

    beanstalk = await getBeanstalk()
    const tokenFacet = await (await ethers.getContractFactory("TokenFacet", account)).deploy()
    console.log(`Token Facet deployed to: ${tokenFacet.address}`)
    const ebip6 = await (await ethers.getContractFactory("InitEBip6", account)).deploy()
    console.log(`EBIP-6 deployed to: ${ebip6.address}`)
    const dc = {
        diamondCut: [
                        [
                            '0x0c9F436FBEf08914c1C68fe04bD573de6e327776',
                            '0',
                            ['0xdf18a3ee', '0x845a022b', '0x82c65124']
                        ],
                        [
                            tokenFacet.address,
                            '0',
                            ['0xd3f4ec6f']
                        ]
                    ],
        initFacetAddress: ebip6.address,
        functionCall: ebip6.interface.encodeFunctionData('init', [])
    }
    if (mock) {
        const receipt = await beanstalk.connect(account).diamondCut(...Object.values(dc))
    } else {
        const encodedDiamondCut = await beanstalk.interface.encodeFunctionData('diamondCut', Object.values(dc))
        console.log(JSON.stringify(dc, null, 4))
        console.log("Encoded: -------------------------------------------------------------")
        console.log(encodedDiamondCut)
        const dcName = `diamondCut-${'InitEBip6'}-${Math.floor(Date.now() / 1000)}-facets.json`
        await fs.writeFileSync(`./diamondCuts/${dcName}`, JSON.stringify({diamondCut: dc, encoded: encodedDiamondCut }, null, 4));
        return dc
    }
}

exports.ebip6 = ebip6