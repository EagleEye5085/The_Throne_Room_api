require 'rails_helper'

describe 'Reviews API' do

  it 'has a list of reviews' do
    VCR.use_cassette('reviews index') do
      t1 = ThroneRoom.create(name: "walmart bathroom", address: "6675 business center dr, highlands ranch, co 80130", directions: "that way", baby_changing_station: 0, bathroom_style: 1, key_code_required: 1)
      create_list(:review, 5)
      get "/api/v1/throne_rooms/#{t1.id}/reviews"

      expect(response).to be_successful

      response_body = JSON.parse(response.body, symbolize_names: true)
      reviews = response_body[:data]

      reviews.each do |review|
        expect(review).to have_key(:id)
        expect(review[:id]).to be_a(String)

        expect(review).to have_key(:attributes)
        expect(review[:attributes][:cleanliness]).to be_a(Integer)
        expect(review[:attributes][:ambiance]).to be_a(Integer)
        expect(review[:attributes][:tp_quality]).to be_a(Integer)
        expect(review[:attributes][:privacy]).to be_an(Integer)
        expect(review[:attributes][:accessibility]).to be_an(Integer)
        expect(review[:attributes][:other_comments]).to be_an(String)
        expect(review[:attributes]).to_not have_key(:created_at)
      end
    end
  end

  it 'can get one review by its ID' do
    VCR.use_cassette('reviews show') do
      t1 = ThroneRoom.create(name: "walmart bathroom", address: "6675 business center dr, highlands ranch, co 80130", directions: "that way", baby_changing_station: 0, bathroom_style: 1, key_code_required: 1)
      create_list(:review, 5)
      id = create(:review).id

      get "/api/v1/throne_rooms/#{t1.id}/reviews/#{id}"

      response_body = JSON.parse(response.body, symbolize_names: true)
      review = response_body[:data]

      expect(response).to be_successful

      expect(review).to have_key(:id)
      expect(review[:id]).to be_a(String)

      expect(review).to have_key(:attributes)
      expect(review[:attributes][:cleanliness]).to be_a(Integer)
      expect(review[:attributes][:ambiance]).to be_a(Integer)
      expect(review[:attributes][:tp_quality]).to be_a(Integer)
      expect(review[:attributes][:privacy]).to be_an(Integer)
      expect(review[:attributes][:accessibility]).to be_an(Integer)
      expect(review[:attributes][:other_comments]).to be_an(String)
      expect(review[:attributes]).to_not have_key(:created_at)
    end
  end

  it "can create a new review and delete it" do
    VCR.use_cassette('reviews create and delete') do
      tr_id = ThroneRoom.create(name: "walmart bathroom", address: "6675 business center dr, highlands ranch, co 80130", directions: "that way", baby_changing_station: 0, bathroom_style: 1, key_code_required: 1).id
      review_params = ({
                      cleanliness: Faker::Number.between(from: 1, to: 5),
                      ambiance: Faker::Number.between(from: 1, to: 5),
                      tp_quality: Faker::Number.between(from: 1, to: 5),
                      privacy: Faker::Number.between(from: 1, to: 5),
                      accessibility: Faker::Number.between(from: 1, to: 5),
                      other_comments: Faker::Lorem.paragraph(sentence_count: 2, supplemental: true),
                      throne_room_id: tr_id,
                      user_id: Faker::Number.digit
                    })

      headers = {"CONTENT_TYPE" => "application/json"}

      post "/api/v1/throne_rooms/#{tr_id}/reviews", headers: headers, params: JSON.generate(review: review_params)

      created_review = Review.last
        # binding.pry
      expect(response).to have_http_status(201)
      expect(created_review.cleanliness).to eq(review_params[:cleanliness])
      expect(created_review.ambiance).to eq(review_params[:ambiance])
      expect(created_review.tp_quality).to eq(review_params[:tp_quality])
      expect(created_review.privacy).to eq(review_params[:privacy])
      expect(created_review.accessibility).to eq(review_params[:accessibility])
      expect(created_review.other_comments).to eq(review_params[:other_comments])

      delete "/api/v1/throne_rooms/#{tr_id}/reviews/#{created_review.id}"

      expect(response).to have_http_status(204)
      expect(Review.count).to eq(0)
      expect{Review.find(created_review.id)}.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  it "updates an existing review" do
    VCR.use_cassette('reviews update') do
      t1 = ThroneRoom.create(name: "walmart bathroom", address: "6675 business center dr, highlands ranch, co 80130", directions: "that way", baby_changing_station: 0, bathroom_style: 1, key_code_required: 1)
      create_list(:review, 5)

      id = create(:review).id
      previous_cleanliness = Review.last.cleanliness
      review_params = { cleanliness: Faker::Number.digit }
      headers = {"CONTENT_TYPE" => "application/json"}

      patch "/api/v1/throne_rooms/#{t1.id}/reviews/#{id}", headers: headers, params: JSON.generate({review: review_params})

      review = Review.find_by(id: id)
      # binding.pry
      expect(response).to be_successful
      expect(review.cleanliness).to_not eq(previous_cleanliness)
      expect(review.cleanliness).to eq(review.cleanliness)
    end
  end

  it 'returns 404 if review is not found' do
    VCR.use_cassette('reviews not found') do
      t1 = ThroneRoom.create(name: "walmart bathroom", address: "6675 business center dr, highlands ranch, co 80130", directions: "that way", baby_changing_station: 0, bathroom_style: 1, key_code_required: 1)
      create_list(:review, 5)
      review = create(:review)
      id = 90654501

      get "/api/v1/throne_rooms/#{t1.id}/reviews/#{id}"

      expect(response).to have_http_status(404)

      delete "/api/v1/throne_rooms/#{t1.id}/reviews/#{id}"

      expect(response).to have_http_status(404)
    end
  end

  it 'returns 404 if review cannot be created' do
    VCR.use_cassette('reviews failed create') do
      t1 = ThroneRoom.create(name: "walmart bathroom", address: "6675 business center dr, highlands ranch, co 80130", directions: "that way", baby_changing_station: 0, bathroom_style: 1, key_code_required: 1)
      create_list(:review, 5)

      review = create(:review)
      review_params = ({
                      cleanliness: Faker::Number.between(from: 1, to: 5),
                      ambiance: Faker::Number.between(from: 1, to: 5),
                      tp_quality: Faker::Number.between(from: 1, to: 5),
                      privacy: Faker::Number.between(from: 1, to: 5),
                      accessibility: Faker::Number.between(from: 1, to: 5),
                      other_comments: Faker::Lorem.paragraph(sentence_count: 2, supplemental: true),
                      throne_room_id: ThroneRoom.create(name: "walmart bathroom", address: "6675 business center dr, highlands ranch, co 80130", directions: "that way", baby_changing_station: 0, bathroom_style: 1, key_code_required: 1).id,
                      # user_id: Faker::Number.digit
                    })

      headers = {"CONTENT_TYPE" => "application/json"}

      post "/api/v1/throne_rooms/#{t1.id}/reviews", headers: headers, params: JSON.generate(review: review_params)


      expect(response).to have_http_status(404)
    end
  end

  it 'returns 404 if review cannot be updated' do
    VCR.use_cassette('reviews failed update') do
      t1 = ThroneRoom.create(name: "walmart bathroom", address: "6675 business center dr, highlands ranch, co 80130", directions: "that way", baby_changing_station: 0, bathroom_style: 1, key_code_required: 1)
      create_list(:review, 5)

      id = create(:review).id
      previous_cleanliness = Review.last.cleanliness
      review_params = { cleanliness: "hello" }
      headers = {"CONTENT_TYPE" => "application/json"}

      patch "/api/v1/throne_rooms/#{t1.id}/reviews/#{id}", headers: headers, params: JSON.generate({review: review_params})

      review = Review.find_by(id: id)

      expect(response).to have_http_status(404)
    end
  end

  it 'returns the 5 most recent reviews' do
    VCR.use_cassette('recent reviews') do
      tr = ThroneRoom.create(name: "walmart bathroom", address: "6675 business center dr, highlands ranch, co 80130", directions: "that way", baby_changing_station: 0, bathroom_style: 1, key_code_required: 1)
      reviews = create_list(:review, 8)

      get "/api/v1/throne_rooms/#{tr.id}/reviews/recent"

      response_body = JSON.parse(response.body, symbolize_names: true)
      reviews = response_body[:data]
      # binding.pry
      expect(reviews.count).to eq(5)
      expect(reviews.first[:id].to_i).to eq(Review.last[:id])
      expect(reviews.last[:id].to_i).to eq(Review.fourth[:id])
      # expect(reviews.pluck(:id).include?(reviews.id)).to eq(false)
    end
  end

  it 'returns 404 if the throne room cannot be found' do
    VCR.use_cassette('reviews no throne') do
      tr = ThroneRoom.create(name: "walmart bathroom", address: "6675 business center dr, highlands ranch, co 80130", directions: "that way", baby_changing_station: 0, bathroom_style: 1, key_code_required: 1)
      get "/api/v1/throne_rooms/999999/reviews/recent"
      # binding.pry
      expect(response).to have_http_status(404)
    end
  end

  it 'has averages of attributes for reviews' do
    VCR.use_cassette('review averages') do
      # review = create(:review)
      t1 = ThroneRoom.create(name: "walmart bathroom", address: "6675 business center dr, highlands ranch, co 80130", directions: "that way", baby_changing_station: 0, bathroom_style: 1, key_code_required: 1)
      tr_id = t1.id
        Review.create!( "cleanliness":1, "ambiance": 1, "tp_quality":1, "privacy":2, "accessibility":2,  "user_id":1,  "other_comments": "eh",  "throne_room_id": tr_id)
        Review.create!( "cleanliness":2, "ambiance": 3, "tp_quality":1, "privacy":1, "accessibility":2,  "user_id":2,  "other_comments": "meh",  "throne_room_id": tr_id)
        Review.create!( "cleanliness":1, "ambiance": 2, "tp_quality":1, "privacy":1, "accessibility":1, "user_id":3,  "other_comments": "it was alright",  "throne_room_id": tr_id)
        Review.create!( "cleanliness":2, "ambiance": 1, "tp_quality":1, "privacy":2, "accessibility":1, "user_id":4,  "other_comments": "ugh",  "throne_room_id": tr_id)

      get "/api/v1/throne_rooms/#{tr_id}/reviews/review_averages"

      # binding.pry

      response_body = JSON.parse(response.body)
      # reviews = response_body[:data]

      expect(response_body.first).to eq("1.5")
      expect(response_body.second).to eq("1.75")
      expect(response_body.third).to eq("1.0")
      expect(response_body.fourth).to eq("1.5")
      expect(response_body.fifth).to eq("1.5")
    end
  end

  it 'has average overall rating' do
    VCR.use_cassette('averages overall') do
      # review = create(:review)
      t1 = ThroneRoom.create(name: "walmart bathroom", address: "6675 business center dr, highlands ranch, co 80130", directions: "that way", baby_changing_station: 0, bathroom_style: 1, key_code_required: 1)
      tr_id = t1.id
        Review.create!( "cleanliness":1, "ambiance": 1, "tp_quality":1, "privacy":2, "accessibility":2,  "user_id":1,  "other_comments": "eh",  "throne_room_id": tr_id)
        Review.create!( "cleanliness":2, "ambiance": 3, "tp_quality":1, "privacy":1, "accessibility":2,  "user_id":2,  "other_comments": "meh",  "throne_room_id": tr_id)
        Review.create!( "cleanliness":1, "ambiance": 2, "tp_quality":1, "privacy":1, "accessibility":1, "user_id":3,  "other_comments": "it was alright",  "throne_room_id": tr_id)
        Review.create!( "cleanliness":2, "ambiance": 1, "tp_quality":1, "privacy":2, "accessibility":1, "user_id":4,  "other_comments": "ugh",  "throne_room_id": tr_id)

      get "/api/v1/throne_rooms/#{tr_id}/reviews/overall_averages"

      response_body = JSON.parse(response.body)
      # reviews = response_body[:data]

      expect(response_body).to eq("1.45")
    end
  end

end
