require 'spec_helper'
require './lib/rails_app_processor'

RSpec.describe RailsAppProcessor do
  let(:app1) do
    Repository.new(name: 'app1', location: 'spec/fixtures/app1')
  end

  let(:app2) do
    Repository.new(name: 'app2', location: 'spec/fixtures/app2')
  end

  def process
    described_class.new(repository: app1).process
    described_class.new(repository: app2).process
  end

  describe 'business_events' do
    subject(:events) { process; BusinessEvent.all }

    it 'creates 3 events' do
      expect(events.count).to eq(3)
    end

    describe ':foo :big_bar event' do
      let(:basic_job) { app1.find_object(class_name: 'BasicJob') }
      let(:basic_job_enqueues_child_job) { app1.find_object(class_name: 'BasicJobEnqueuesChildJob') }

      subject(:event) { process; BusinessEvent.find(topic: :foo, name: :big_bar) }

      it { is_expected.not_to be_nil }
      its(:jobs) { is_expected.to include(basic_job) }
      its(:jobs) { is_expected.to include(basic_job_enqueues_child_job) }
    end

    describe ':foo :small_bar event' do
      let(:app2_small_bar_job) { app2.find_object(class_name: 'App2SmallBarJob') }

      subject(:event) { process; BusinessEvent.find(topic: :foo, name: :small_bar) }

      it { is_expected.not_to be_nil }
      its(:jobs) { is_expected.to include(app2_small_bar_job) }
    end

    describe ':foo :noop event' do
      subject(:event) { process; BusinessEvent.find(topic: :foo, name: :noop) }

      it { is_expected.not_to be_nil }
      its(:jobs) { is_expected.to be_empty }
    end
  end

  describe 'app1 processed jobs' do
    subject(:objects) { process; app1.objects }

    it 'creates 6 objects' do
      expect(objects.count).to eq(6)
    end

    describe 'basic job' do
      let(:foo_small_bar_event) { BusinessEvent.find(topic: :foo, name: :small_bar) }
      subject { process; app1.find_object(class_name: 'BasicJob') }

      it { is_expected.not_to be_nil }
      its(:name) { is_expected.to eq('BasicJob') }
      its(:full_name) { is_expected.to eq('app1 BasicJob') }
      its(:child_objects) { is_expected.to be_empty }
      its(:events_published) { is_expected.to include(foo_small_bar_event) }
    end

    describe 'job with module' do
      subject { process; app1.find_object(class_name: 'JobWithModule') }

      it { is_expected.not_to be_nil }
      its(:name) { is_expected.to eq('JobWithModule') }
      its(:full_name) { is_expected.to eq('app1 MoreJobs::JobWithModule') }
      its(:child_objects) { is_expected.to be_empty }
    end

    describe 'basic job enqueues child job' do
      let(:child_job) { app1.find_object(class_name: 'ChildJob') }
      subject { process; app1.find_object(class_name: 'BasicJobEnqueuesChildJob') }

      it { is_expected.not_to be_nil }
      its(:name) { is_expected.to eq('BasicJobEnqueuesChildJob') }
      its(:full_name) { is_expected.to eq('app1 BasicJobEnqueuesChildJob') }
      its(:child_objects) { is_expected.to include(child_job) }
    end

    describe 'child job' do
      let(:basic_job_enqueues_child_job) { app1.find_object(class_name: 'BasicJobEnqueuesChildJob') }
      subject { process; app1.find_object(class_name: 'ChildJob') }

      it { is_expected.not_to be_nil }
      its(:name) { is_expected.to eq('ChildJob') }
      its(:full_name) { is_expected.to eq('app1 ChildJob') }
      its(:child_objects) { is_expected.to be_empty }
      end

    describe 'operation job' do
      let(:do_stuff_operation) { app1.find_object(class_name: 'DoStuffOperation') }
      subject { process; app1.find_object(class_name: 'OperationJob') }

      it { is_expected.not_to be_nil }
      its(:name) { is_expected.to eq('OperationJob') }
      its(:full_name) { is_expected.to eq('app1 OperationJob') }
      its(:child_objects) { is_expected.to include(do_stuff_operation) }
    end

    describe 'do stuff operation' do
      let(:basic_job) { app1.find_object(class_name: 'BasicJob') }
      let(:foo_noop_event) { BusinessEvent.find(topic: :foo, name: :noop) }
      subject { app1.find_object(class_name: 'DoStuffOperation') }

      it { is_expected.not_to be_nil }
      its(:name) { is_expected.to eq('DoStuffOperation') }
      its(:full_name) { is_expected.to eq('app1 DoStuffOperation') }
      its(:child_objects) { is_expected.to include(basic_job) }
      its(:events_published) { is_expected.to include(foo_noop_event) }
    end
  end

  describe 'app2 processed jobs' do
    subject(:objects) { process; app2.objects }

    it 'creates 2 jobs' do
      expect(objects.count).to eq(2)
    end

    describe 'app2_small_bar_job' do
      subject { process; app2.find_object(class_name: 'App2SmallBarJob') }

      it { is_expected.not_to be_nil }
      its(:name) { is_expected.to eq('App2SmallBarJob') }
      its(:full_name) { is_expected.to eq('app2 App2SmallBarJob') }
      its(:child_objects) { is_expected.to be_empty }
      its(:events_published) { is_expected.to be_empty }
    end

    describe 'big bar generate job' do
      let(:foo_big_bar_event) { BusinessEvent.find(topic: :foo, name: :big_bar) }
      subject { process; app2.find_object(class_name: 'BigBarGenerateJob') }

      it { is_expected.not_to be_nil }
      its(:name) { is_expected.to eq('BigBarGenerateJob') }
      its(:full_name) { is_expected.to eq('app2 BigBarGenerateJob') }
      its(:child_objects) { is_expected.to be_empty }
      its(:events_published) { is_expected.to include(foo_big_bar_event) }
    end
  end
end
