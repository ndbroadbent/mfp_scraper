require 'spec_helper'

describe MFPScraper do
  MFPScraper.class_eval do
    register_path :test_string_path, '/test/string'
    register_path :test_proc_path, ->(params) { "/test/#{test_proc_method}" }

    def test_proc_method
      'proc'
    end
  end

  let(:mfp) { MFPScraper.new({}) }

  describe "#path_for" do
    it 'should return a string path' do
      expect(mfp.path_for(:test_string_path)).to eq '/test/string'
    end

    it 'should correctly evaluate and return a path for a proc' do
      expect(mfp.path_for(:test_proc_path)).to eq '/test/proc'
    end
  end

  describe "#url_for" do
    it 'should return the correct URL' do
      expect(mfp.url_for(:test_string_path)).to eq 'http://www.myfitnesspal.com/test/string'
    end
  end
end
