require 'sinatra'
require 'pry-byebug'
require 'httparty'
require 'json'
require 'rubyXL'

HEADERS = %w[pid barcode description enumeration_a enumeration_b enumeration_c
             enumeration_d enumeration_e enumeration_f enumeration_g enumeration_h
             chronology_i chronology_j chronology_k chronology_l chronology_m pages
             receiving_operator physical_material_type.value policy.value
             inventory_number]

get '/' do
  erb :index
end

get '/:mmsid/:hldid' do
  mmsid = params[:mmsid]
  hldid = params[:hldid]

  alma = BulkOperations.new

  content_type "application/octet-stream"
  attachment "#{mmsid}_#{hldid}.xlsx"

  workbook = RubyXL::Workbook.new
  worksheet = workbook[0]

  worksheet.add_cell(0, 0, 'mmsid')
  worksheet.add_cell(0, 1, 'hldid')
  HEADERS.each_with_index do |h,i|
    worksheet.add_cell(0, i+2, h.split('.').first)
  end

  item_data = [alma.fetch(mmsid, hldid)].flatten

  item_data.each_with_index do |item,i|
    worksheet.add_cell(i+1, 0, mmsid)
    worksheet.add_cell(i+1, 1, hldid)
    HEADERS.each_with_index do |h,j|
      worksheet.add_cell(i+1, j+2, item['item_data'].dig(*h.split('.')))
    end
  end

  return workbook.stream
end

post '/' do
  alma = BulkOperations.new
  workbook = RubyXL::Parser.parse(params['updatefile'][:tempfile])
  worksheet = workbook[0]
  successful_updates = 0

  worksheet.each_with_index do |r,i|
    # Skip headers
    next if i == 0

    rowdata = Hash.new
    rowdata['mmsid'] = r[0].value
    rowdata['hldid'] = r[1].value

    HEADERS.each_with_index { |h,j|
      path = h.split('.')
      if path.length > 1
        key = path.shift
        terminal = path.pop

        rowdata[key] = {}
        current = rowdata[key]

        path.each do |p|
          current[p] = {}
          current = current[p]
        end

        current[terminal] = r[j+2]&.value || ''
      else
        rowdata[path.first] = r[j+2]&.value || ''
      end
    }

    success = alma.update(rowdata)
    successful_updates += 1 if success == 200
  end

   erb :index, locals: {update_count: successful_updates}
end

class BulkOperations

  def initialize
    @cache = Hash.new()
  end
  
  def fetch(mmsid, hldid)
    return @cache[[mmsid,hldid]] if @cache.has_key?([mmsid,hldid])

    offset = 0
    limit =100 
    url = "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/#{mmsid}/holdings/#{hldid}/items?limit=#{limit}&offset=#{offset}&apikey=#{ENV['ALMA_API_KEY']}"

    response = JSON(HTTParty.get(url, :headers => { "Accept": "application/json" }).body)
    while offset + limit < response['total_record_count']
      offset += limit
      url = "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/#{mmsid}/holdings/#{hldid}/items?limit=#{limit}&offset=#{offset}&apikey=#{ENV['ALMA_API_KEY']}"
      next_chunk = JSON(HTTParty.get(url, :headers => { "Accept": "application/json" }).body)
      response['item'].concat(next_chunk['item'])
    end

    response = response['item']
    @cache[[mmsid,hldid]] = response

    return response
  end
  
  def update(data)
    mmsid, hldid, pid = data['mmsid'], data['hldid'], data['pid']
    apidata = fetch(mmsid, hldid)

    url = "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/#{mmsid}/holdings/#{hldid}/items/#{pid}"
    query = {"apikey" => ENV['ALMA_API_KEY']}
    headers = {"Content-Type" => "application/json"}
    body = apidata.select{ |item| item['item_data']['pid'] == pid } .first

    if body.nil? 
      # TODO: handle this
    end

    data.each do |k,v|
      next if ['mmsid','hldid','pid'].member?(k)
      body['item_data'][k] = v
    end
  
    response = HTTParty.put(url, :headers => headers, :query => query, :body => body.to_json)
    return response.code
  end
end
