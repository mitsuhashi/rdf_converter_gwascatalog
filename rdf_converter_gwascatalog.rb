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
    "pubmed" => "<http://rdf.ncbi.nlm.nih.gov/pubmed/>",
    "med2rdf" => "<http://med2rdf.org/ontology/>",
    "ensg" => "<http://identifiers.org/ensembl/>"
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
        GWASCatalog.prefixes if $prefixes
        while line = f.gets
          ary = line.chomp.split(/\t/, -1)
          if ary.size < keys.size
            ary = ary + Array.new(keys.size - ary.size){""}
          end
          association = [keys, ary].transpose.to_h
          assc = foo(association)
          puts turtle(assc)
        end
      end
    end

    def self.foo(association)

      if /ENSG/ =~ association[:snp_gene_ids]
        snp_gene_ids_ary = association[:snp_gene_ids].split(", ").map{|e| "ensg:#{e}"}.join(", ")
        association[:snp_gene_ids] = snp_gene_ids_ary
      else
        association[:snp_gene_ids] = "\"\""
      end
      if association[:or_or_beta].to_f <= 1.0
        association[:odds_ratio] = association[:or_or_beta].to_f
        association[:beta] = "\"NA\""
      else
        association[:odds_ratio] = "\"NA\""
        association[:beta] = association[:or_or_beta].to_f
      end
      unless association[:upstream_gene_id] == ""
        association[:upstream_gene_id] = "ensg:#{association[:upstream_gene_id]}"
      else
        association[:upstream_gene_id] = "\"\""
      end
      unless association[:downstream_gene_id] == ""
        association[:downstream_gene_id] = "ensg:#{association[:downstream_gene_id]}"
      else
        association[:downstream_gene_id] = "\"\""
      end
      if association[:downstream_gene_distance] == ""
        association[:downstream_gene_distance] = "\"\""
      end
      if association[:upstream_gene_distance] == ""
        association[:upstream_gene_distance] = "\"\""
      end

      if association[:risk_allele_frequency] == "NR"
        association[:risk_allele_frequency] = "\"NR\""
      elsif association[:risk_allele_frequency] == ""
        association[:risk_allele_frequency] = "\"\""
      elsif /^[\d\.]+$/ =~ association[:risk_allele_frequency]
        if /\.$/ =~ association[:risk_allele_frequency]
          association[:risk_allele_frequency] = "0.0"
        end
      else
        association[:risk_allele_frequency] = "\"\""
      end

      if /\"/ =~ association[:strongest_snp_risk_allele]
        association[:strongest_snp_risk_allele] = association[:strongest_snp_risk_allele].gsub("\"", "")
      end
      if /\\/ =~ association[:reported_genes]
        association[:reported_genes] = association[:reported_genes].gsub('"', '').gsub(/\\/, '')
      end

      unless association[:mapped_trait] == ""
        if /\"/ =~ association[:mapped_trait]
          association[:mapped_trait] = association[:mapped_trait].gsub(/\"/, "\\\"")
        end
      else
        association[:mapped_trait] = ""
      end
      if association[:mapped_trait_uri] == ""
        association[:mapped_trait_uri] = "\"\""
      else
        association[:mapped_trait_uri] = association[:mapped_trait_uri].split(' ').map{|uri| "<#{uri}>"}.join(', ')
      end
      association
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
        [] a gwas:Association ;
          terms:region "#{h[:region]}" ;
          terms:chr_id "#{h[:chr_id]}" ;
          terms:chr_pos "#{h[:chr_pos]}" ;
          terms:reported_genes '''#{h[:reported_genes]}''' ;
          terms:mapped_genes "#{h[:mapped_genes]}" ;
          terms:upstream_gene_id #{h[:upstream_gene_id]} ;
          terms:downstream_gene_id #{h[:downstream_gene_id]} ;
          terms:snp_gene_ids #{h[:snp_gene_ids]} ;
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
          terms:p_value_mlog #{h[:pvalue_mlog]} ;
          terms:p_value_text "#{h[:p_value_text].gsub(/\\/, "")}" ;
          terms:odds_ratio #{h[:odds_ratio]} ;
          terms:beta #{h[:beta]} ;
          terms:ci_text "#{h[:ci_text]}" ;
          terms:platform_snp_passing_qc "#{h[:platform_snp_passing_qc]}" ;
          terms:cnv "#{h[:cnv]}" ;
          terms:mapped_trait "#{h[:mapped_trait]}" ;
          terms:mapped_trait_uri #{h[:mapped_trait_uri]} ;
          terms:study study:#{h[:study_accession]} ;
          terms:genotyping_technology "#{h[:genotyping_technology]}" ;
          dct:date "#{h[:date_added_to_catalog]}"^^xsd:date ;
          dct:references pubmed:#{h[:pubmedid]} ;
          gwas:has_pubmed_id "#{h[:pubmedid]}" .

      TURTLE
    end
  end
end

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
