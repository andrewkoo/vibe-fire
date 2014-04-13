require "./gracenote/HTTP"
require 'rexml/document'
require "crack"
include REXML

class Rhythm
    
    attr_accessor :clientID, :clientTag, :userID, :apiURL
    genreList = Hash.new()
    genreList[:"Latin"] = "25982"
    genreList[:"Blues"] = "36060"
    genreList[:"Electronica"] = "36055"
    genreList[:"Country"] = "36059"
    genreList[:"Pop"] = "36056"
    genreList[:"Folk"] = "25971"
    genreList[:"Punk"] = "36051"
    genreList[:"New Age"] = "36062"
    genreList[:"Rock"] = "25964"
    genreList[:"R&B"] = "36057"
    genreList[:"Soundtrack"] = "36063"
    genreList[:"Reggae"] = "36065"
    genreList[:"Christian"] = "25976"
    genreList[:"Children"] = "25980"
    genreList[:"Alternative"] = "25961"
    genreList[:"Metal"] = "36053"
    genreList[:"Rap"] = "36058"
    genreList[:"Dance & House"] = "36054"
    genreList[:"Jazz"] = "25974"
    genreList[:"Indie"] = "36052"
    
    # Function: initialize
    # Sets the following instance variables
    #   clientID
    #   clientTag
    #   userID
    #   apiURL
    def initialize (spec)
        if(spec[:clientID].nil? || spec[:clientID] == "")
            raise "clientID cannot be nil"
        end
        if(spec[:clientTag].nil? || spec[:clientTag] == "")
            raise "clientTag cannot be nil"
        end
        
        @clientID = spec[:clientID]
        @clientTag = spec[:clientTag]
        @userID = spec[:userID].nil? ? nil : spec[:userID]
        @apiURL = "https://c1981696.web.cddbp.net/webapi/xml/1.0/"
    end
    
    # public methods
    public
    # Function: registerUser
    # Registers a user and returns userID
    def registerUser (clientID = nil)
        if(clientID.nil?)
            clientID = "1981696-C695EDBB082367813EE5FF05AE3D58FF"
        end
        
        if not @userID.nil?
            puts "user already registered. No need to register again"
            return @userID
        end
        #puts "here"
        #send req to server and get user ID
        data =  "<QUERIES>
        <QUERY CMD= \"REGISTER\">
        <CLIENT>"+ clientID +"</CLIENT>
        </QUERY>
        </QUERIES>"
        resp = api(data)
        resp = checkRES resp
        @userID = resp['RESPONSES']['RESPONSE']['USER']
        
        return @userID
    end
    
    # Function: findTrack
    # Finds a track
    # Arguments:
    #   artistName
    #   albumTitle
    #   trackTitle
    #   matchMode
    def createStation(artistName, songName, genre, returnCount="10", focusPopularity="500", focusSimilarity="500")
        if @userID == nil
            registerUser
        end
        body = constructRadioQueryBody(artistName, songName, genre, returnCount, focusPopularity, focusSimilarity)
        data = api(constructQueryReq(body))
        return data.body
    end
    
    
    ###################################################### protected methods ######################################################
    protected
    # Function: api
    # execute a query on gracenote webapi
    # Arguments:
    #   query
    def api (query)
        return HTTP.post(@apiURL, query)
    end
    
    # Function: constructQueryReq
    # Constructs Query
    # Arguments:
    #   body
    #   command
    def constructQueryReq(body, command = "RADIO_CREATE")
        #construct the XML query
        return  "<QUERIES>
        <AUTH>
        <CLIENT>"+ @clientID + "-" + @clientTag + "</CLIENT>
        <USER>"+ @userID + "</USER>
        </AUTH>
        <QUERY CMD=\"" + command + "\">
        " + body + "
        </QUERY>
        </QUERIES>"
    end
    
    # Function: constructAlbumQueryBody
    # Constructs query body
    # Arguments:
    #   artist
    #   song
    #   genre
    #   number of songs to return
    #   command
    #   matchMode
    #   focusPopularity
    #   focusSimilarity
    def constructRadioQueryBody(artistName, songName, genre, returnCount="10", focusPopularity="500", focusSimilarity="500")
        body = ""
        if artistName != "" and songName != ""
            body += "<SEED TYPE=\"TEXT\">
            <TEXT TYPE=\"ARTIST\">" + artistName + "</TEXT>
            <TEXT TYPE=\"TRACK\">" + songName + "</TEXT>
            </SEED>"
        end
        if genre != ""
            body += "<SEED TYPE=\"TEXT\">
            <TEXT TYPE=\"GENRE\">" + genre[:genre] + "</TEXT>
            </SEED>"
        end
        body += "<OPTION>
        <PARAMETER>RETURN_COUNT</PARAMETER>
        <VALUE>"+returnCount+"</VALUE>
        </OPTION>
        <OPTION>
        <PARAMETER>FOCUS_POPULARITY</PARAMETER>
        <VALUE>"+focusPopularity+"</VALUE>
        </OPTION>
        <OPTION>
        <PARAMETER>FOCUS_SIMILARITY</PARAMETER>
        <VALUE>"+focusSimilarity+"</VALUE>
        </OPTION>
        <OPTION>
        <PARAMETER>DMCA</PARAMETER>
        <VALUE>YES</VALUE>
        </OPTION>"
        return body
    end
    end


    # Function: checkRES
    # Checks an XML response and converts it into json
    # Arguments:
    #   resp
    def checkRES resp
        if resp.code.to_s != '200'
            raise "Problem!! Got #{resp.code} with #{resp.message}"
        end
        json = nil
        begin
            json = Crack::XML.parse resp.body
            rescue Exception => e
            raise e
        end
        
        status = json['RESPONSES']['RESPONSE']['STATUS'].to_s
        case status
            when "ERROR"
            raise "ERROR in response"
            when "NO_MATCH"
            raise "No match found"
            else
            if status != "OK"
                raise "Problems found in the response"
            end
        end
        return json
    end

    # Function: parseAlbumRES
    # Parse's an XML response
    # Arguments:
    #   resp
    def parseAlbumRES resp
        json = nil
        begin
            json = checkRES resp
            rescue Exception => e
            raise e
        end
        output = Array.new
        data = Array.new
        if json['RESPONSES']['RESPONSE']['ALBUM'].class.to_s != 'Array'
            data.push json['RESPONSES']['RESPONSE']['ALBUM']
            else
            data = json['RESPONSES']['RESPONSE']['ALBUM']
        end
        
        data.each do |a|
            obj = Hash.new
            
            obj[:album_gnid]         = a["GN_ID"].to_i
            obj[:album_artist_name]  = a["ARTIST"].to_s
            obj[:album_title]        = a["TITLE"].to_s
            obj[:album_year]         = a["DATE"].to_s
            obj[:genre]              = _getOETElem(a["GENRE"])
            obj[:album_art_url]      = _getAttribElem(a["URL"], "TYPE", "COVERART")
            
            # Artist metadata
            obj[:artist_image_url]  = _getAttribElem(a["URL"], "TYPE", "ARTIST_IMAGE")
            obj[:artist_bio_url]    = _getAttribElem(a["URL"], "TYPE", "ARTIST_BIOGRAPHY")
            obj[:review_url]        = _getAttribElem(a["URL"], "TYPE", "REVIEW")
            
            # If we have artist OET info, use it.
            if not a["ARTIST_ORIGIN"].nil?
                obj[:artist_era]    = _getOETElem(a["ARTIST_ERA"])
                obj[:artist_type]   = _getOETElem(a["ARTIST_TYPE"])
                obj[:artist_origin] = _getOETElem(a["ARTIST_ORIGIN"])
                else
                # If not available, do a fetch to try and get it instead.
                obj = merge_recursively(obj, fetchOETData(a["GN_ID"]) )
            end
            
            # Parse track metadata if there is any.
            obj[:tracks] = Array.new()
            tracks = Array.new()
            if a["TRACK"].class.to_s != 'Array'
                tracks.push a["TRACK"]
                else
                tracks = a["TRACK"]
            end
            tracks.each do |t|
                track = Hash.new()
                
                track[:track_number]      = t["TRACK_NUM"].to_s
                track[:track_gnid]        = t["GN_ID"].to_s
                track[:track_title]       = t["TITLE"].to_s
                track[:track_artist_name] = t["ARTIST"].to_s
                
                # If no specific track artist, use the album one.
                if t["ARTIST"].nil?
                    track[:track_artist_name] = obj[:album_artist_name]
                end
                
                track[:mood]              = _getOETElem(t["MOOD"])
                track[:tempo]             = _getOETElem(t["TEMPO"])
                
                # If track level GOET data exists, overwrite metadata from album.
                if not t["GENRE"].nil?
                    obj[:genre]         = _getOETElem(t["GENRE"])
                end
                if not t["ARTIST_ERA"].nil?
                    obj[:artist_era]    = _getOETElem(t["ARTIST_ERA"])
                end
                if not t["ARTIST_TYPE"].nil?
                    obj[:artist_type]   = _getOETElem(t["ARTIST_TYPE"])
                end
                if not t["ARTIST_ORIGIN"].nil?
                    obj[:artist_origin] = _getOETElem(t["ARTIST_ORIGIN"])
                end
                obj[:tracks].push track
            end
            output.push obj
        end
        return output
    end