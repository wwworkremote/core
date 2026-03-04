# frozen_string_literal: true

module Blorgh
  class JotsController < ApplicationController
    before_action :set_jot, only: %i[show edit update destroy]

    # GET /jots
    def index
      @jots = Jot.all
    end

    # GET /jots/1
    def show; end

    # GET /jots/new
    def new
      @jot = Jot.new
    end

    # GET /jots/1/edit
    def edit; end

    # POST /jots
    def create
      @jot = Jot.new(jot_params)

      if @jot.save
        redirect_to @jot, notice: 'Jot was successfully created.'
      else
        render :new, status: :unprocessable_content
      end
    end

    # PATCH/PUT /jots/1
    def update
      if @jot.update(jot_params)
        redirect_to @jot, notice: 'Jot was successfully updated.'
      else
        render :edit, status: :unprocessable_content
      end
    end

    # DELETE /jots/1
    def destroy
      @jot.destroy
      redirect_to jots_url, notice: 'Jot was successfully destroyed.'
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_jot
      @jot = Jot.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def jot_params
      params.require(:jot).permit(:data)
    end
  end
end
