# frozen_string_literal: true

require 'tmpdir'
require 'base64'

class Competitions::Score::ListPrintGeneratorsController < CompetitionNestedController
  default_resource resource_class: Score::ListPrintGenerator, through_association: :score_list_print_generators

  def show
    send_pdf(Exports::Pdf::Score::MultiList, args: [@competition, resource_instance.print_list_extended]) && return
    redirect_to format: :pdf
  end

  def new
    lists = resource_instance.possible_lists.sort
    resource_instance.print_list = "#{lists.first&.id}\ncolumn\n#{lists.second&.id}"
    resource_instance.save

    redirect_to edit_competition_score_list_print_generator_path(id: resource_instance)
  end

  def edit
    @lists = resource_instance.possible_lists.sort
  end

  def update
    @lists = resource_instance.possible_lists.sort
    @list_print_generator.assign_attributes(list_print_generator_params)
    if params[:preview]
      Dir.mktmpdir do |dir_path|
        multi_list = Exports::Pdf::Score::MultiList.perform(@competition, @list_print_generator.print_list_extended)
        File.binwrite("#{dir_path}/in.pdf", multi_list.bytestream)
        command = "cd #{Shellwords.escape(dir_path)} ; " \
                  'convert -strip -background white -alpha remove -alpha off -quality 100 -density 100 in.pdf out.png'
        Open3.capture2(command)
        pages_pngs = if multi_list.pdf.page_count == 1
                       ["#{dir_path}/out.png"]
                     else
                       (0..(multi_list.pdf.page_count - 1)).map do |i|
                         "#{dir_path}/out-#{i}.png"
                       end
                     end
        render json: { pages: pages_pngs.map { |src| Base64.encode64(File.read(src)) } }
      end
    elsif @list_print_generator.save
      redirect_to competition_score_list_print_generators_path, notice: :saved
    else
      flash.now[:alert] = :check_errors
      render action: :edit, status: :unprocessable_content
    end
  end

  protected

  def list_print_generator_params
    params.require(:score_list_print_generator).permit(:print_list)
  end
end
