class Api::V1::ThroneRoomsController < ApplicationController

  def index
    @thrones = ThroneRoom.close_to(address)
    render json: ThroneRoomSerializer.new(ThroneRoom.all)
  end

  def show
    if ThroneRoom.exists?(params[:id])
      render json: ThroneRoomSerializer.new(ThroneRoom.find(params[:id]))
    else
      render json: {
        error: 'Throne Room not available'
        }, status: 404
    end
  end

  def create
    throne_room = ThroneRoom.new(throne_room_params)
    if throne_room.save
      render json: ThroneRoomSerializer.new(throne_room), status: 201
    else
      render status: 404
    end
  end

  def update
    throne_room = ThroneRoom.find(params[:id])
    if throne_room.update(throne_room_params)
      render json: ThroneRoomSerializer.new(ThroneRoom.find(params[:id])), status: :accepted
    else
      render status: 404
    end
  end

  def destroy
    if ThroneRoom.exists?(params[:id])
      ThroneRoom.destroy(params[:id])
    else
      render status: 404
    end
  end

  private
  def throne_room_params
    params[:throne_room].permit(:name, :address, :latitude, :longitude,:directions, :baby_changing_station, :bathroom_style, :key_code_required)
  end
end
