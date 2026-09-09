autoload(:Kubeclient, 'kubeclient')

describe ManageIQ::Providers::Kubevirt::Inventory::Collector::PartialRefresh do
  let(:kubeclient) { double("kubeclient") }
  let(:ems)        { FactoryBot.create(:ems_kubevirt) }
  let(:collector)  { described_class.new(ems, notices) }
  let(:notices)    { [] }

  before { allow(ems).to receive(:kubeclient).and_return(kubeclient) }

  context "with no notices" do
    it "collections are empty" do
      expect(collector.nodes).to          be_empty
      expect(collector.vms).to            be_empty
      expect(collector.vm_instances).to   be_empty
      expect(collector.templates).to      be_empty
      expect(collector.instance_types).to be_empty
    end
  end

  context "#pvc" do
    let(:pvc) { Kubeclient::Resource.new(:metadata => {:name => "my-pvc", :namespace => "default"}) }

    it "fetches the pvc from the api by name and namespace" do
      expect(kubeclient).to receive(:get_persistent_volume_claim).with("my-pvc", "default").and_return(pvc)
      expect(collector.pvc("my-pvc", "default")).to eq(pvc)
    end

    it "returns nil when the pvc does not exist" do
      allow(kubeclient).to receive(:get_persistent_volume_claim).and_raise(Kubeclient::ResourceNotFoundError.new(404, "not found", nil))
      expect(collector.pvc("missing-pvc", "default")).to be_nil
    end
  end

  context "with a vm notice" do
    let(:vm)        { Kubeclient::Resource.new(:apiVersion => "kubevirt.io/v1", :kind => "VirtualMachine", :metadata => {:name => "my-vm", :namespace => "default", :uid => SecureRandom.uuid})}
    let(:vm_notice) { Kubeclient::Resource.new(:type => "MODIFIED", :object => vm) }
    let(:notices)   { [vm_notice] }

    it "#vms" do
      expect(collector.vms).to include(vm_notice)
    end

    context "with multiple notices for the same object" do
      let(:vm_notice2) { Kubeclient::Resource.new(:type => "MODIFIED", :object => vm) }
      let(:notices)    { [vm_notice, vm_notice2] }

      it "only exposes a single notice" do
        expect(collector.vms.count).to eq(1)
      end
    end
  end
end
