#!/usr/bin/env ruby

require 'csv'
require 'optparse'

module GWASCatalog

  Prefixes = {
    "rdf" =>    "<http://www.w3.org/1999/02/22-rdf-syntax-ns#>",
    "terms" =>  "<http://med2rdf.org/gwascatalog/terms/>",
    "gwas" =>   "<http://rdf.ebi.ac.uk/terms/gwas/>",
    "oban" =>   "<http://purl.org/oban/>",
    "owl" =>    "<http://www.w3.org/2002/07/owl#>",
    "xsd" =>    "<http://www.w3.org/2001/XMLSchema#>",
    "rdfs" =>   "<http://www.w3.org/2000/01/rdf-schema#>",
    "ro" =>     "<http://www.obofoundry.org/ro/ro.owl#>",
    "study" =>  "<http://www.ebi.ac.uk/gwas/studies/>",
    "dct" =>    "<http://purl.org/dc/terms/>",
    "pubmed" => "<http://rdf.ncbi.nlm.nih.gov/pubmed/>"
  }

  def prefixes
    Prefixes.each do |pfx, uri|
      print "@prefix #{pfx}: #{uri} .\n"
    end
    puts "\n"
  end
  module_function :prefixes

  class Study

    def self.rdf(file, prefixes = false)
      File.open(file) do |f|
        keys = parse_header(f.gets)
        GWASCatalog.prefixes if $prefixes
        while line = f.gets
          ary = line.chomp.split("\t")
          study = [keys, ary].transpose.to_h
          puts turtle(study)
        end
      end
    end

    def self.parse_header(header)
      header.chomp
            .split("\t") 
            .map{|e| e.downcase.gsub(/[\-\s\/]/, '_')
            .gsub(/[\[\]]/, '')
            .to_sym}
    end

    def self.turtle(h)
      turtle = <<~"TURTLE"
        study:#{h[:study_accession]} a gwas:Study ;
          dct:identifier "#{h[:study_accession]}" ;
          dct:date "#{h[:date_added_to_catalog]}"^^xsd:date ;
          dct:references pubmed:#{h[:pubmedid]} ;
          gwas:has_pubmed_id "#{h[:pubmedid]}"^^xsd:string ;
          dct:description "#{h[:disease_trait]}"@en ;
          terms:initial_sample_size "#{h[:initial_sample_size]}"@en ;
          terms:replication_sample_size "#{h[:replication_sample_size]}"@en ;
          terms:platform_snps_passing_qc "#{h[:platform_snps_passing_qc]}" ;
          terms:association_count #{h[:association_count]} ;
          terms:mapped_trait #{h[:mapped_trait_uri].size == 0 ? "\"\"" : h[:mapped_trait_uri].split(", ").map{|e| "<#{e}>"}.join(', ')} ;
          terms:genotyping_technology "#{h[:genotyping_technology]}" .

      TURTLE
    end
  end

  class Association

    def self.rdf(file, prefixes = false)
      File.open(file) do |f|
        keys = parse_header(f.gets)
        keys.to_a.each_with_index {|e, i| print "#{i}\t#{e}\n"}
        GWASCatalog.prefixes if $prefixes
        while line = f.gets
          ary = line.chomp.split(/\t/, -1)
          if ary.size < keys.size
            ary = ary + Array.new(keys.size - ary.size){""}
          end
          association = [keys, ary].transpose.to_h
          raf = association[:risk_allele_frequency]
          association[:risk_allele_frequency] = "NR" if raf == "NR"
          puts turtle(association)
        end
      end
    end

    def self.parse_header(header)
      header.chomp
            .split("\t")
            .map{|e| e.downcase.gsub(/[\-\s\/]/, '_')
            .gsub(/[\[\]\(\)\%]/, '')
            .gsub(/95_/, '')
            .to_sym}
    end

    def self.turtle(h)
      turtle = <<~"TURTLE"
        [] a :Variation ;
          terms:region "#{h[:region]}" ;
          terms:chr_id "#{h[:chr_id]}" ;
          terms:reported_genes "#{h[:reported_genes]}" ;
          terms:mapped_genes "#{h[:mapped_genes]}" ;
          terms:upstream_gene_id ensg:#{h[:upstream_gene_id]} ;
          terms:downstream_gene_id ensg:#{h[:downstream_gene_id]} ;
          terms:snp_gene_ids #{h[:snp_gene_ids].split(", ").map{|e| "ensg:#{e}"}.join(", ")} ;
          terms:upstream_gene_distance #{h[:upstream_gene_distance]} ;
          terms:downstream_gene_distance #{h[:downstream_gene_distance]} ;
          terms:strongest_snp_risk_allele "#{h[:strongest_snp_risk_allele]}" ;
          terms:snps "#{h[:snps]}" ;
          terms:merged "#{h[:merged]}" ;
          terms:snp_id_current "#{h[:snp_id_current]}" ;
          terms:context "#{h[:context]}" ;
          terms:intergenic "#{h[:intergenic]}" ;
          terms:risk_allele_frequency #{h[:risk_allele_frequency]} ;
          terms:p_value #{h[:p_value]} ;
          terms:p_value_mlog "#{h[:p_value_mlog]}" ;
          terms:p_value_text "#{h[:p_value_text]}" ;
          terms:or_or_beta "#{h[:or_or_beta]}" ;
          terms:ci_text "#{h[:ci_text]}" ;
          terms:platform_snp_passing_qc "#{h[:platform_snp_passing_qc]}" ;
          terms:cnv "#{h[:cnv]}" ;
          dct:date "#{h[:date_added_to_catalog]}"^^xsd:date ;
          dct:references pubmed:#{h[:pubmedid]} ;
          gwas:has_pubmed_id "#{h[:pubmedid]}"^^xsd:string .

      TURTLE
    end
  end
end

=begin
[:date_added_to_catalog, :pubmedid, :first_author, :date, :journal, :link, :study, :disease_trait, :initial_sample_size, :replication_sample_size, :region, :chr_id, :chr_pos, :reported_genes, :mapped_gene, :upstream_gene_id, :downstream_gene_id, :snp_gene_ids, :upstream_gene_distance, :downstream_gene_distance, :strongest_snp_risk_allele, :snps, :merged, :snp_id_current, :context, :intergenic, :risk_allele_frequency, :p_value, :pvalue_mlog, :p_value_text, :or_or_beta, :"95_ci_text", :platform_snps_passing_qc, :cnv]
=end

def help
  print "Usage: > ruby rdf_converter_gwascatalog.rb [options] <file>\n"
end


params = ARGV.getopts('hps:a:', 'help', 'prefixes', 'study:', 'association:')

if params["help"] || params["h"]
  help
  exit
end

$prefixes = true                                    if params["prefixes"]
$prefixes = true                                    if params["p"]
GWASCatalog::Study.rdf(params["study"])             if params["study"]
GWASCatalog::Study.rdf(params["s"])                 if params["s"]
GWASCatalog::Association.rdf(params["association"]) if params["association"]
GWASCatalog::Association.rdf(params["a"])           if params["a"]


=begin

def turtle(h)

  turtle = <<"TURTLE"
study:#{h[:study_accession]} a gwas:Study ;
  dct:identifier "#{h[:study_accession]}" ;
  dct:date "#{h[:date_added_to_catalog]}"^^xsd:date ;
  dct:references pubmed:#{h[:pubmedid]} ;
  gwas:has_pubmed_id "#{h[:pubmedid]}"^^xsd:string ;
  dct:description "#{h[:disease_trait]}"@en ;
  terms:initial_sample_size "#{h[:initial_sample_size]}"@en ;
  terms:replication_sample_size "#{h[:replication_sample_size]}"@en ;
  terms:platform_snps_passing_qc "#{h[:platform_snps_passing_qc]}" ;
  terms:association_count #{h[:association_count]} ;
  terms:mapped_trait #{h[:mapped_trait_uri].size == 0 ? "\"\"" : h[:mapped_trait_uri].split(", ").map{|e| "<#{e}>"}.join(', ')} ;
  terms:genotyping_technology "#{h[:genotyping_technology]}" .

TURTLE

end

file = open(ARGV.shift)

header = file.gets
keys = header.chomp.split("\t").map{|e| e.downcase.gsub(/[\-\s\/]/, '_').gsub(/[\[\]]/, '').to_sym}

prefixes

while line = file.gets
  ary = line.chomp.split("\t")
  study = [keys, ary].transpose.to_h
#  p study
  puts turtle(study)
end

=end
