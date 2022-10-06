import { expect, assert, use as chaiUse } from "chai";
import { NomadEnv } from "../src/nomadenv";
import Docker from "dockerode";
import { LocalAgent } from "../src/agent";
import chaiAsPromised from "chai-as-promised";
import { NomadDomain } from "../src/domain";

chaiUse(chaiAsPromised);

describe("NomadDomain test", () => {
    //TODO: We should implement any-network connection logic and test accordingly.
    it('can create a valid NomadEnvironment', async () => {
        // Creation
        const le = new NomadEnv({
            domain: 1,
            id: "0x" + "20".repeat(20),
        });
        expect(le).to.exist;
        
        let tDomainNumber = 1;
        let jDomainNumber = 2;
      
        if (process.env.tDomainNumber) {
          tDomainNumber = parseInt(process.env.tDomainNumber);
        }
      
        if (process.env.jDomainNumber) {
          jDomainNumber = parseInt(process.env.jDomainNumber);
        }

        // Can add domains with undefined forkURL
        const tom = NomadDomain.newHardhatNetwork("tom", tDomainNumber, { forkurl: le.forkUrl, weth: le.wETHAddress, nomadEnv: le });
        const jerry = NomadDomain.newHardhatNetwork("jerry", jDomainNumber, { forkurl: le.forkUrl, weth: le.wETHAddress, nomadEnv: le });
        le.addNetwork(tom.network);
        le.addNetwork(jerry.network);
        assert.isTrue(le.domains.includes(le.domains[0]));

        expect(le.govNetwork).to.equal(le.domains[0]);
        // SDK
        expect(le.bridgeSDK).to.exist;
        expect(le.coreSDK).to.exist;

        // Can up agents
        await le.upAgents();

        expect(le.domains[0].agents).to.exist;
        expect(le.domains[1].agents).to.exist;

        assert.isTrue(await le.tDomain?.areAgentsUp());
        assert.isTrue(await le.tDomain?.agents!.updater.status());
        assert.isTrue(await le.tDomain?.agents!.relayer.status());
        assert.isTrue(await le.tDomain?.agents!.processor.status());
        assert.isTrue(await le.jDomain?.areAgentsUp());
        assert.isTrue(await le.jDomain?.agents!.updater.status());
        assert.isTrue(await le.jDomain?.agents!.relayer.status());
        assert.isTrue(await le.jDomain?.agents!.processor.status());

        const docker = new Docker();

        const tUpdater = (le.tDomain?.agents!.updater as LocalAgent).containerName();
        const tRelayer = (le.tDomain?.agents!.relayer as LocalAgent).containerName();
        const tProcessor = (le.tDomain?.agents!.processor as LocalAgent).containerName();

        const jUpdater = (le.jDomain?.agents!.updater as LocalAgent).containerName();
        const jRelayer = (le.jDomain?.agents!.relayer as LocalAgent).containerName();
        const jProcessor = (le.jDomain?.agents!.processor as LocalAgent).containerName();

        assert.isTrue((await docker.getContainer(tUpdater).inspect()).State.Running);
        assert.isTrue((await docker.getContainer(tRelayer).inspect()).State.Running);
        assert.isTrue((await docker.getContainer(tProcessor).inspect()).State.Running);

        assert.isTrue((await docker.getContainer(jUpdater).inspect()).State.Running);
        assert.isTrue((await docker.getContainer(jRelayer).inspect()).State.Running);
        assert.isTrue((await docker.getContainer(jProcessor).inspect()).State.Running);

        await le.downAgents();
        assert.isFalse(await le.tDomain?.areAgentsUp());
        assert.isFalse(await le.jDomain?.areAgentsUp()); 

        await assert.isRejected(docker.getContainer(tUpdater).inspect(), "no such container");
        await assert.isRejected(docker.getContainer(tRelayer).inspect(), "no such container");
        await assert.isRejected(docker.getContainer(tProcessor).inspect(), "no such container");
        await assert.isRejected(docker.getContainer(jUpdater).inspect(), "no such container");
        await assert.isRejected(docker.getContainer(jRelayer).inspect(), "no such container");
        await assert.isRejected(docker.getContainer(jProcessor).inspect(), "no such container");

        // Can up networks
        await le.upNetworks();

        assert.isTrue(await le.tDomain?.network.isConnected());
        assert.isTrue(await le.jDomain?.network.isConnected());

        assert.isTrue(await le.tDomain?.network.isConnected());
        assert.isTrue(await le.jDomain?.network.isConnected());

        await le.down();
        assert.isFalse(await le.tDomain?.network.isConnected());
        assert.isFalse(await le.jDomain?.network.isConnected());
    });

});